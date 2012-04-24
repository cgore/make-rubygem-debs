# Copyright (c) 2012, Christopher Mark Gore,
# All rights reserved.
#
# 8729 Lower Marine Road, Saint Jacob, Illinois 62281 USA.
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
    gems = Dir.chdir topdir do
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
        deb_name = name.sub "-", "_"
        deb_file = "rubygem-#{deb_name}_#{version}_all.deb"
        if File.exists? deb_file
          puts "Successfully created #{deb_file}."
        else
          raise RuntimeError, "Failed to create #{deb_file}."
        end
      end
    end
  end
end
