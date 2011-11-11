# Copyright 2011 Exavideo LLC.
# 
# This file is part of videohub_control.
# 
# videohub_control is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# 
# videohub_control is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with videohub_control.  If not, see <http://www.gnu.org/licenses/>.

require 'patchbay'
require 'socket'
require 'json'

def input_data(label)
    { :label => label }
end

def output_data(label)
    { :label => label }
end

$inputs = [
    input_data('Camera 1 (asynchronous)'),  # 01
    input_data('Camera 2 (asynchronous)'),  # 02
    input_data('Camera 3 (asynchronous)'),  # 03
    input_data('Camera 4 (asynchronous)'),  # 04
    input_data('Camera 5 (synchronous)'),   # 05
    input_data('Camera 6 (synchronous)'),   # 06
    input_data('MOTU SD-SDI Output'),       # 07
    input_data('MOTU HD-SDI Output'),       # 08
    input_data('Switcher Preview'),         # 09
    input_data('Switcher Program'),         # 10
    input_data('Switcher Aux1'),            # 11
    input_data('Switcher Aux2'),            # 12
    input_data('Switcher Aux3'),            # 13
    input_data('Switcher Aux4/Pgm2'),       # 14
    input_data('Unused'),                   # 15
    input_data('Unused'),                   # 16
    input_data('Replay Output'),            # 17
    input_data('Graphics (Dirty 1)'),       # 18
    input_data('Graphics (Dirty 0)'),       # 19
    input_data('Unused'),                   # 20
    input_data('Unused'),                   # 21
    input_data('Unused'),                   # 22
    input_data('Unused'),                   # 23
    input_data('Unused'),                   # 24
    input_data('Unused'),                   # 25
    input_data('Unused'),                   # 26
    input_data('Unused'),                   # 27
    input_data('Unused'),                   # 28
    input_data('Unused'),                   # 29
    input_data('Unused'),                   # 30
    input_data('Unused'),                   # 31
    input_data('Unused'),                   # 32
    input_data('Unused'),                   # 33
    input_data('Unused'),                   # 34
    input_data('Unused'),                   # 35
    input_data('Unused'),                   # 36
    input_data('Unused'),                   # 37
    input_data('Unused'),                   # 38
    input_data('Unused'),                   # 39
    input_data('Unused'),                   # 40
]

$outputs = [
    output_data('MOTU HD-SDI Input'),           # 01
    output_data('MOTU SD-SDI Input'),           # 02
    output_data('Switcher Input 1'),            # 03
    output_data('Switcher Input 2'),            # 04
    output_data('Switcher Input 3'),            # 05
    output_data('Switcher Input 4'),            # 06
    output_data('Switcher Input 5'),            # 07
    output_data('Switcher Input 6'),            # 08
    output_data('Switcher Input 7'),            # 09
    output_data('Switcher Input 8'),            # 10
    output_data('Switcher Input 9'),            # 11
    output_data('Switcher Input 10'),           # 12
    output_data('Switcher Input 11'),           # 13
    output_data('Switcher Input 12'),           # 14
    output_data('Unused'),                      # 15
    output_data('Unused'),                      # 16
    output_data('Replay Source 1'),             # 17
    output_data('Replay Source 2'),             # 18
    output_data('Replay Source 3'),             # 19
    output_data('Replay Source 4'),             # 20
    output_data('Replay Source 5'),             # 21
    output_data('Replay Source 6'),             # 22
    output_data('Replay Source 7'),             # 23
    output_data('Graphics Input'),              # 24
    output_data('Recorder Input 1'),            # 25
    output_data('Recorder Input 2'),            # 26
    output_data('Recorder Input 3'),            # 27
    output_data('Unused'),                      # 28
    output_data('Unused'),                      # 29
    output_data('Unused'),                      # 30
    output_data('Unused'),                      # 31
    output_data('HDMI Out 32'),                 # 32
    output_data('SDI Out 33'),                  # 33
    output_data('SDI Out 34'),                  # 34
    output_data('SDI Out 35'),                  # 35
    output_data('SDI Out 36'),                  # 36
    output_data('SDI Out 37'),                  # 37
    output_data('SDI Out 38'),                  # 38
    output_data('SDI Out 39'),                  # 39
    output_data('SDI Out 40'),                  # 40
]

class Router
    def initialize(host)
        @host = host
        @port = 9990
    end

    def test
        sock = open_socket
        p @chunks
    end

    def get_routes
        open_socket # and discard it
        @chunks['VIDEO OUTPUT ROUTING:'].map do |route|
            route.split(/ /)[1].to_i
        end
    end

    def set_route(output, input)
        sock = open_socket
        sock.puts("VIDEO OUTPUT ROUTING:")
        sock.puts("#{output} #{input}")
        sock.puts("")
        result = sock.readline.chomp
        if result != 'ACK'
            fail "Router did not acknowledge route update... try again?"
        end
    end

private
    def open_socket
        sock = TCPSocket.new @host, @port
        chunk = nil
        chunks = { }
        while true
            line = sock.readline.chomp
            if line =~ /:$/
                # chunk header line
                chunk = line
            elsif line == ''
                # end of chunk
                puts "end of chunk #{chunk}"
                if chunk == 'VIDEO OUTPUT LOCKS:'
                    # that is all the router will send
                    break
                else 
                    # we have left the chunk
                    chunk = nil
                end
            else
                if chunk
                    chunks[chunk] ||= []
                    chunks[chunk] << line
                end
            end
        end

        @chunks = chunks
        sock
    end
end

class RouterController < Patchbay
    get '/output/:id' do
        output_id = params[:id].to_i
        routes = @router_host.get_routes    
        render :json => { :input => routes[output_id] }.to_json
    end

    put '/output/:id' do
        output_id = params[:id].to_i
        input = incoming_json['input']
        puts "would route #{output_id} from #{input}"
        @router_host.set_route(output_id, input)
        render :json => { :input => input }.to_json
    end

    get '/outputs' do
        result = @router_host.get_routes.zip($outputs).map do |a|
            p a
            input = a[0]
            data = a[1]

            { :input => input }.merge(data)
        end

        render :json => result.to_json
    end

    get '/inputs' do
        render :json => $inputs.to_json
    end

    attr_accessor :router_host

    self.files_dir = 'public_html'
end

app = RouterController.new
app.router_host = Router.new('rpitv-video-router')
app.run(:Host => '::', :Port => '3001')

