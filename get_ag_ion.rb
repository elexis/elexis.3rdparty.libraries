#!/usr/bin/env ruby

require 'fileutils'
require 'zip/zip'
require 'pp'
require "rexml/document"
include REXML  # so that we don't have to prefix everything with REXML::...
ARGV.size == 1 ? NewVersion = ARGV[0] : NewVersion = ''

root = 'http://ubion.ion.ag/downloads/free/noa4e/plugins/'
plugins = [
 'ag.ion.bion.workbench.office.editor.activation.nl1_2.0.14.jar', 
 'ag.ion.bion.workbench.office.editor.activation_2.0.14.jar',
 'ag.ion.bion.workbench.office.editor.activation_2.0.9.jar',
 'ag.ion.bion.workbench.office.editor.core_2.0.14.jar',
 'ag.ion.bion.workbench.office.editor.ui.nl1_2.0.14.jar',
 'ag.ion.bion.workbench.office.editor.ui_2.0.14.jar',
 'ag.ion.noa4e.search.nl1_2.0.14.jar',
 'ag.ion.noa4e.search_2.0.14.jar',
 'ag.ion.noa4e.ui.nl1_2.0.14.jar',
 'ag.ion.noa4e.ui_2.0.14.jar',
 'ag.ion.noa_2.2.3.jar',
]

def patch_text_preferences(jarname)
  xmlName = 'plugin.xml'
  mfName  = 'META-INF/MANIFEST.MF'
  
  newName = jarname.sub('.jar',"#{NewVersion}.jar")
  puts "Patching #{jarname} -> #{newName}"
  FileUtils.cp(jarname, newName, :verbose => true) unless newName.eql?(jarname)
  @jarfile                   = Zip::ZipFile.open(jarname, 'w+')
  doc = Document.new @jarfile.read(xmlName)
  @manifest =  @jarfile.read(mfName)
  @jarfile.close
  res = []
  doc.root.elements.collect { |x| res << x if /org.eclipse.ui.preferencePages/.match(x.attributes['point']) }
  res[0].elements.each{
    |x|    
    next unless /ag.ion.noa4e.ui.preferences.LocalOfficeApplicationPreferencePage/.match(x.attributes['id'])
    x.attributes['category'] = 'ch.elexis.preferences.Texterstellung'
    x.attributes['name'] = 'OpenOffice.org'
    x = Zip::ZipFile.open(newName) { |zipfile| zipfile.remove(xmlName); zipfile.remove(mfName); }
    Zip::ZipFile.open(newName) { |zipfile| 
                                 zipfile.get_output_stream(xmlName) { |f| f.write(doc.to_s) } 
                                 zipfile.get_output_stream(mfName)  { |f| 
                                                                      version = /^Bundle-Version: (.*)$/.match(@manifest)
                                                                    pp version
                                                                      f.write(@manifest.sub(version[1].chomp, version[1].chomp+NewVersion)) } 
                               }
    break
  } if res and res[0] and res[0].elements
  newName
end

plugins.each {
  |plugin|
    cmd = "wget #{root}/#{plugin}"
  puts cmd if $VERBOSE
  File.exists?(plugin) ? puts("Skipping #{cmd}") : system(cmd)
  next unless /ag.ion.noa4e.ui_/.match(plugin)
  plugin = patch_text_preferences(plugin) if /ag.ion.noa4e.ui_/.match(plugin)
  version = plugin.split(/_|\.jar/)
  artifact_id = plugin.split('_')[0]
  artifact_id = artifact_id.sub('ag.ion.', '')
  cmd = "mvn install:install-file -Dfile=#{plugin} -DgroupId=ag.ion -DartifactId=#{artifact_id} -Dversion=#{version[1]} -Dpackaging=jar"
  puts "Installing #{plugin} via #{cmd}"
  puts cmd  if $VERBOSE
  exit 1 unless system(cmd)
}
