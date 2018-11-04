require 'mkmf'
require 'rbconfig'

extension_name = 'oj'
dir_config(extension_name)

parts = RUBY_DESCRIPTION.split(' ')
type = parts[0]
type = type[4..-1] if type.start_with?('tcs-')
is_windows = RbConfig::CONFIG['host_os'] =~ /(mingw|mswin)/
platform = RUBY_PLATFORM
version = RUBY_VERSION.split('.')
puts ">>>>> Creating Makefile for #{type} version #{RUBY_VERSION} on #{platform} <<<<<"

dflags = {
  'RUBY_TYPE' => type,
  (type.upcase + '_RUBY') => nil,
  'RUBY_VERSION' => RUBY_VERSION,
  'RUBY_VERSION_MAJOR' => version[0],
  'RUBY_VERSION_MINOR' => version[1],
  'RUBY_VERSION_MICRO' => version[2],
  'HAS_RB_TIME_TIMESPEC' => (!is_windows &&
			     !['arm-linux-gnueabi',
			       'arm-linux-gnueabihf',
			       'i386-linux-gnu',
			       'mips-linux-gnu',
			       'mipsel-linux-gnu'].include?(platform) &&
			     'ruby' == type &&
			     ('1.9.3' == RUBY_VERSION || '2' <= version[0])) ? 1 : 0,
  'HAS_NANO_TIME' => ('ruby' == type && ('1' == version[0] && '9' == version[1]) || '2' <= version[0]) ? 1 : 0,
  'HAS_IVAR_HELPERS' => is_windows ? 0 : 1,
  'IS_WINDOWS' => is_windows ? 1 : 0,
  'HAS_DATA_OBJECT_WRAP' => ('ruby' == type && '2' == version[0] && '3' <= version[1]) ? 1 : 0,
  'RSTRUCT_LEN_RETURNS_INTEGER_OBJECT' => ('ruby' == type && '2' == version[0] && '4' == version[1] && '1' >= version[2]) ? 1 : 0,
}
# This is a monster hack to get around issues with 1.9.3-p0 on CentOS 5.4. SO
# some reason math.h and string.h contents are not processed. Might be a
# missing #define. This is the quick and easy way around it.
if 'x86_64-linux' == RUBY_PLATFORM && '1.9.3' == RUBY_VERSION && '2011-10-30' == RUBY_RELEASE_DATE
  begin
    dflags['NEEDS_STPCPY'] = nil if File.read('/etc/redhat-release').include?('CentOS release 5.4')
  rescue Exception
  end
else
  dflags['NEEDS_STPCPY'] = nil if is_windows
end

dflags['OJ_DEBUG'] = true unless ENV['OJ_DEBUG'].nil?

dflags.each do |k,v|
  if v.nil?
    $CPPFLAGS += " -D#{k}"
  else
    $CPPFLAGS += " -D#{k}=#{v}"
  end
end

$CPPFLAGS += ' -Wall'
#puts "*** $CPPFLAGS: #{$CPPFLAGS}"
create_makefile(File.join(extension_name, extension_name))

%x{make clean}
