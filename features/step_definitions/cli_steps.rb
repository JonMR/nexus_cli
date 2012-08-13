require 'aruba/api'
require 'json'
require 'jsonpath'
World(Aruba::Api)

When /^I call the nexus "(.*?)" command$/ do |command|
  step "I run `nexus-cli #{command} --overrides=#{get_overrides_string}`"
end

When /^I push an artifact with the GAV of "(.*)"$/ do |gav|
  groupId, artifact_id, version, extension = gav.split(":")
  file = File.new(File.join(temp_dir, "#{artifact_id}-#{version}.#{extension}"), 'w')
  file.puts "some data"
  file.close
  step "I run `nexus-cli push #{gav} #{file.path} --overrides=#{get_overrides_string}`"
end

When /^I pull an artifact with the GAV of "(.*?)" to a temp directory$/ do |gav|
  step "I run `nexus-cli pull #{gav} --destination #{temp_dir} --overrides=#{get_overrides_string}`"
end

Then /^I should have a copy of the "(.*?)" artifact in a temp directory$/ do |fileName|
  File.exists?(File.join(temp_dir, fileName)).should == true
end

When /^I delete an artifact with the GAV of "(.*)"$/ do |gav|
  nexus_remote.delete_artifact(gav)
end

When /^I edit the "(.*?)" files "(.*?)" field to true$/ do |file, field|
  Dir.chdir('tmp/aruba') do
    json = JSON.parse(File.read(File.join(File.expand_path("."), file)))
    File.open(File.join(File.expand_path("."), file), "w+") do |opened|
      json["data"]["globalRestApiSettings"][field] = true
      opened.write(JSON.pretty_generate(json))
    end
  end
end

When /^I update global settings uiTimeout to (\d+) and upload the json string$/ do |value|  
  json = JSON.parse(nexus_remote.get_global_settings_json)
  edited_json = JsonPath.for(json).gsub("$..uiTimeout") {|v| value.to_i}.to_hash
  nexus_remote.upload_global_settings(JSON.dump(edited_json))
end

Then /^the file "([^"]*)" should contain:$/ do |file, partial_content|
  check_file_content(file, partial_content, true)
end
