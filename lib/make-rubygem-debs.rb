# -*- coding: utf-8 -*-

# Copyright © 2012-2014, Christopher Mark Gore,
# Soli Deo Gloria,
# All rights reserved.
#
# 2317 South River Road, Saint Charles, Missouri 63303 USA.
# Web: http://www.cgore.com
# Email: cgore@cgore.com
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# * Redistributions of source code must retain the above copyright
#   notice, this list of conditions and the following disclaimer.
#
# * Redistributions in binary form must reproduce the above copyright
#   notice, this list of conditions and the following disclaimer in the
#   documentation and/or other materials provided with the distribution.
#
# * Neither the name of Christopher Mark Gore nor the names of other
#   contributors may be used to endorse or promote products derived from
#   this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


if RUBY_VERSION < "1.9"
  raise RuntimeError, "Your version of Ruby is too old!"
end

module MakeRubygemDebs
  def self.gem_executable_presence_check executable, gem = executable
    result = `which #{executable}`
    if result.empty?
      raise RuntimeError, "Please install #{gem}, try `gem install #{gem}`."
    end
    return result
  end

  FPM = gem_executable_presence_check 'fpm'
  BUNDLE = gem_executable_presence_check 'bundle', 'bundler'

  def self.make_rubygem_debs topdir
    depends = []
    gems = Dir.chdir topdir do
      if not File.exists? "Gemfile.lock"
        raise RuntimeError, "There is no Gemfile.lock within #{topdir}."
      end
      `bundle list`.split("\n")[1..-1].map do |line|
        name, version = line.split[1..2]
        [name, version[1..-2]]
      end
    end
    debdir = "#{topdir}/rubygem-debs"
    `mkdir -p "#{debdir}"`
    Dir.chdir debdir do
      gems.each do |name, version|
        puts "Trying to make a .deb for #{name} #{version} ..."
        `fpm -s gem -t deb -v #{version} #{name}`
        deb_name = "rubygem-" + name.gsub("_", "-")
        deb_file = "#{deb_name}_#{version}"
        deb = Dir.entries('.').select {|file| file.match deb_file}
        if not deb.empty?
          puts "Successfully created #{deb[0]}."
        else
          raise RuntimeError, "Failed to a .deb for #{name} #{version}."
        end
        depends << "#{deb_name} (>= #{version})"
      end
      control = File.open 'control', 'w'
      control.write "Depends: #{depends.join ", "}\n"
      control.close
    end
  end
end
