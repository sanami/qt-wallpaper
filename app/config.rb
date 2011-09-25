require 'rubygems'
require 'ostruct'
require 'pp'
require 'pathname'

require 'bundler'
Bundler.require

ROOT_PATH = File.expand_path('../../', __FILE__)
#puts ROOT_PATH

def ROOT(file)
	File.join(ROOT_PATH, file)
end

# Required folders
['app', 'lib'].each do |folder|
	$: << ROOT(folder)
end
#pp $:

# Search for required files
required_files = ['misc.rb', 'qt/misc.rb', 'settings.rb']

path = Pathname.new(File.dirname(__FILE__))
name = 'shared'

depth = 0
dir = path + name
until dir.directory?
	depth += 1
	raise "#{name} no found" if depth > 10

	path = path.parent
	dir = path + name
end

#pp dir

required_files.each do |file_name|
	require dir + file_name
end


#$console_codec = 'ibm866' # Для работы из командной строки
$debug = true # Нет диалога закрытия
Qt.debug_level = Qt::DebugLevel::Minimal
