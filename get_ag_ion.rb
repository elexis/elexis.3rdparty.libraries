#!/usr/bin/env ruby

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

require 'pp'
plugins.each {
  |plugin|
    cmd = "wget #{root}/#{plugin}"
  puts cmd if $VERBOSE
  File.exists?(plugin) ? puts("Skipping #{cmd}") : system(cmd)
  version = plugin.split(/_|\.jar/)
  artifact_id = plugin.split('_')[0]
  artifact_id = artifact_id.sub('ag.ion.', '')
  cmd = "mvn install:install-file -Dfile=#{plugin} -DgroupId=ag.ion -DartifactId=#{artifact_id} -Dversion=#{version[1]} -Dpackaging=jar"
  puts "Installing #{plugin}"
  puts cmd  if $VERBOSE
  exit 1 unless system(cmd)
}