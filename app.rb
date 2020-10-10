# I will sync all files found in environment variables starting with SYNC_FILES

# e.g. if SYNC_FILES_1="xyz.json::https://www.example.com/x.json"
# then I will grab https://www.example.com/x.json and save it to the bucket as xyz.json
# I'll repeat this for all found environment variables of this form.

require 'net/http'
require 'aws-sdk-s3'

REQUIRED_ENV_VARS = %W(SPACES_NAME SPACES_KEY SPACES_SECRET SPACES_ENDPOINT)
missing_vars = REQUIRED_ENV_VARS.select { |var| ENV[var].nil? || ENV[var] == '' }
fail("You forgot to pass these env vars:\n\n%s\n" % missing_vars.join("\n")) unless missing_vars.length == 0

SPACES_NAME = ENV['SPACES_NAME']
SPACES_KEY = ENV['SPACES_KEY']
SPACES_SECRET = ENV['SPACES_SECRET']
SPACES_ENDPOINT = ENV['SPACES_ENDPOINT']
DOWNLOADS_DIR = File.join(Dir.pwd, 'downloads')


SYNC_FILES_SEPARATOR = '::'
SYNC_FILES = ENV.select { |k,_ | k.start_with?("SYNC_FILES_") }.values.map {|str| str.split(SYNC_FILES_SEPARATOR)}

fail("Nothing to sync! Populate some env vars starting with SYNC_FILES_ to use this utility.") if SYNC_FILES.length == 0
def digital_ocean_client
  Aws::S3::Client.new(
    access_key_id: SPACES_KEY,
    secret_access_key: SPACES_SECRET,
    endpoint: "https://%s" % SPACES_ENDPOINT,
    region: 'us-east-1'
  )
end

def upload_file(source_file, space_file)
  client = digital_ocean_client
  client.put_object({
    bucket: SPACES_NAME,
    key: space_file,
    body: IO.read(source_file),
    acl: "public-read"
  })
  url = "https://#{SPACES_NAME}.#{SPACES_ENDPOINT}/#{space_file}"
  puts "Uploaded #{url}"
  url
end

def download_file(uri, filename)
  Dir.mkdir(DOWNLOADS_DIR) unless Dir.exist? DOWNLOADS_DIR
  local_filename = File.join(DOWNLOADS_DIR, filename)
  uri = URI(uri)
  Net::HTTP.start(uri.host, uri.port, use_ssl: true) do |http|
    request = Net::HTTP::Get.new uri
  
    http.request request do |response|
      raise RuntimeError, "Not successful: #{response.code} #{response.message} for #{uri}" unless response.code == "200"
      open local_filename, 'w' do |io|
        response.read_body do |chunk|
          io.write chunk
        end
      end
    end
  end
  local_filename
end

SYNC_FILES.each do | entry |
  puts "Bad configuration in SYNC_FILES_ variable: `#{entry.join(SYNC_FILES_SEPARATOR)}` " and next unless entry.length == 2
  upload_name, url = entry
  puts "About to copy:\nFrom this url: #{url}\n  to this file: #{upload_name}"
  temp_name = '%s.tmp' % rand(99999999)
  local_name = download_file(url, temp_name)
  destination_url = upload_file(local_name, upload_name)
  puts "Successfully copied:\nFrom this url: #{url}\n  to this url: #{destination_url}"
end
