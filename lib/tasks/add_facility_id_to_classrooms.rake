# Add crontask to server in order to run this at a specified time
#   run crontab -e
#================================
#   49 3 * * * /bin/bash -l -c 'cd /home/deployer/apps/vodsecurityproduction/current && RAILS_ENV=production /home/deployer/.rbenv/shims/bundle exec rake devicinator >> /home/deployer/apps/vodsecurityproduction/shared/log/cronstuff.log 2>&1'
#================================

# https://en.wikipedia.org/wiki/Cron
# https://medium.com/@pawlkris/scheduling-tasks-in-rails-with-cron-and-using-the-whenever-gem-34aa68b992e3

# This task is needed for tests
desc "This will find FacilityID for classroom"
task check_room_for_facility_id: :environment do

  auth_token = AuthTokenApi.new("aa", "classrooms")
  result = auth_token.get_auth_token
  if result['success']
    access_token = result['access_token']
  else
    puts "No access_token. Error: " + result['error']
    exit
  end
  campus_codes = [100]

  classrooms = ClassroomApi.new(access_token)

  facility_id = 'SKB3600'
  result = classrooms.get_classroom_info(ERB::Util.url_encode(facility_id))
  puts result

end

# The task will add FacilityID to every classroom which is needed to get info 
# about classroom_characteristics and classroom_contacts from APIs
# Rooms were added to the database from the BuidingsApi and that data did not have FacilityIDs

desc "This will find FacilityID for classroom for [campus_codes]"
task add_facility_id_to_classrooms: :environment do

  auth_token = AuthTokenApi.new("aa", "classrooms")
  result = auth_token.get_auth_token
  if result['success']
    access_token = result['access_token']
  else
    puts "No access_token. Error: " + result['error']
    exit
  end
  campus_codes = [100]
  # include buildings that are not in the campuses described by campus_codes
  # "BuildingRecordNumber": 1000440, "BuildingLongDescription": "MOORE EARL V BLDG", 
  # "BuildingRecordNumber": 1000234, "BuildingLongDescription": "FRANCIS THOMAS JR PUBLIC HEALTH",
  # "BuildingRecordNumber": 1000204, "BuildingLongDescription": "VAUGHAN HENRY FRIEZE PUBLIC HEALTH BUILDING",
  # "BuildingRecordNumber": 1000333, "BuildingLongDescription": "400 NORTH INGALLS BUILDING",
  # "BuildingRecordNumber": 1005224, "BuildingLongDescription": "STAMPS AUDITORIUM",
  # "BuildingRecordNumber": 1005059, "BuildingLongDescription": "WALGREEN CHARLES R JR DRAMA CENTER",
  buildings_codes = [1000440, 1000234, 1000204, 1000333, 1005224, 1005059]

  api = ClassroomApi.new(access_token)

  time = Benchmark.measure {
    api.add_facility_id_to_classrooms(campus_codes, buildings_codes)
  }
  puts "Add FacilityID for classroom Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_facility_id_logger_api.log for errors or warnings"
end
