require 'faraday'
require 'json'
require 'thor'

class API

    BASE_URL = 'https://not-a-db.com'

    def setup_request(request, body: nil, auth: false)
        if !body.nil?
            request.headers['Content-Type'] = 'application/json'
            request.body = body.to_json
        end

        if auth
            request.headers['Authorization'] = "Bearer #{@token}"
        end
    end

    def make_request(method, url, body: nil, auth: false)
        @token = 'eyJhbGciOiJIUzI1NiJ9.eyJpZCI6IjVmMzAzMjJjOWE0YjkxNGEwMGRiZmE1ZiIsIm5hbWUiOiJKdWFuIiwiZW1haWwiOiJqY2JhZ2VzOTVAZ21haWwuY29tIn0.JNuE-jW2AeGQ9tRagMXMJrxWWhqutXMrvNGZ8dMLvwg'
        if auth && @token.nil?
            return 401, {'message' => 'You are not logged in. Make sure you run login EMAIL PASSWORD first'}
        end

        response = case method
        when :get
            Faraday.get(url) {|request| setup_request(request, body: body, auth: auth)}
        when :post
            Faraday.post(url) {|request| setup_request(request, body: body, auth: auth)}
        when :delete
            Faraday.delete(url) {|request| setup_request(request, body: body, auth: auth)}
        end

        [response.status, JSON.parse(response.body)]
    end

    def get(url, auth: false)
        make_request(:get, url, auth: auth)
    end

    def post(url, body: nil, auth: false)
        make_request(:post, url, body: body, auth: auth)
    end

    def delete(url, auth: false)
        make_request(:delete, url, auth: auth)
    end

    def login(email, password)
        status, body = post("#{BASE_URL}/login", body: {email: email, password: password})
        if status != 200
            [false, body['message']]
        else
            @token = body['token']
            [true, nil]
        end
    end

    def get_services(service_id: nil)
        url = "#{BASE_URL}/_admin/service"
        if !service_id.nil?
            url += "/#{service_id}"
        end

        status, body = get(url, auth: true)
        if status != 200
            [false, body['message']]
        elsif service_id.nil?
            [true, body['services']]
        else
            [true, [body]]
        end
    end

    def create_service(name)
        status, body = post("#{BASE_URL}/_admin/service", body: {name: name}, auth: true)
        if status != 200
            [false, body['message']]
        else
            [true, body]
        end
    end

    def set_custom_host(service_id, custom_host)
        status, body = post("#{BASE_URL}/_admin/service/#{service_id}/custom_host", body: {custom_host: custom_host}, auth: true)
        if status != 200
            [false, body['message']]
        else
            [true, body['message']]
        end
    end

    def delete_custom_host(service_id)
        status, body = delete("#{BASE_URL}/_admin/service/#{service_id}/custom_host", auth: true)
        if status != 200
            [false, body['message']]
        else
            [true, body['message']]
        end
    end

    def delete_service(service_id)
        status, body = delete("#{BASE_URL}/_admin/service/#{service_id}", auth: true)
        if status != 200
            [false, body['message']]
        else
            [true, body['message']]
        end
    end

end

class CLI < Thor

    def initialize(*args)
        super(*args)
        @api = API.new
    end

    def self.exit_on_failure?
        true
    end

    desc 'login EMAIL PASSWORD', 'Login into the system'
    def login(email, password)
        ok, result = @api.login(email, password)
        if !ok
            puts "❌ Error: #{result}"
        else
            puts '🎉 Done, you are logged in!'
        end
    end

    desc 'get_services', 'Get information about services'
    option :id, type: :string, required: false
    def get_services
        ok, result = @api.get_services(service_id: options[:id])
        if !ok
            puts "❌ Error: #{result}"
        else
            puts JSON.pretty_generate(result)
        end
    end

    desc 'create_service NAME', 'Create a new service'
    def create_service(name)
        ok, result = @api.create_service(name)
        if !ok
            puts "❌ Error: #{result}"
        else
            puts JSON.pretty_generate(result)
        end
    end

    desc 'set_custom_host SERVICE_ID CUSTOM_HOST', 'Set a custom host for the given SERVICE_ID'
    def set_custom_host(service_id, host)
        ok, result = @api.set_custom_host(service_id, host)
        if !ok
            puts "❌ Error: #{result}"
        else
            puts "🎉 #{result}"
        end
    end

    desc 'delete_custom_host SERVICE_ID', 'Delete the custom host for the given SERVICE_ID'
    def delete_custom_host(service_id)
        ok, result = @api.delete_custom_host(service_id)
        if !ok
            puts "❌ Error: #{result}"
        else
            puts "🎉 #{result}"
        end
    end

    desc 'delete_service SERVICE_ID', 'Delete the service with the given SERVICE_ID'
    def delete_service(service_id)
        ok, result = @api.delete_service(service_id)
        if !ok
            puts "❌ Error: #{result}"
        else
            puts "🎉 #{result}"
        end
    end

end

CLI.start(ARGV)
