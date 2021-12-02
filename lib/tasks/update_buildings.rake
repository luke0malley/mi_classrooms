# Add crontask to server in order to run this at a specified time
#   run crontab -e
#================================
#   49 3 * * * /bin/bash -l -c 'cd /home/deployer/apps/vodsecurityproduction/current && RAILS_ENV=production /home/deployer/.rbenv/shims/bundle exec rake devicinator >> /home/deployer/apps/vodsecurityproduction/shared/log/cronstuff.log 2>&1'
#================================

# https://en.wikipedia.org/wiki/Cron
# https://medium.com/@pawlkris/scheduling-tasks-in-rails-with-cron-and-using-the-whenever-gem-34aa68b992e3

# The task will get info about all buildings (only for the Central Campus)
# and update buildings records or add new builodings if they are not in the database
# If a building is in the app db, but not in the API, a warning will be added to the log file

desc "This will update campus buildings for [campus_codes] campuses"
task update_buildings: :environment do

  auth_token = AuthTokenApi.new("bf", "buildings")
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

  buildings_codes = [1000440, 1000234, 1000204, 1000333, 1005224, 1005059, 1005347]
  
  api = BuildingsApi.new(access_token)
  time = Benchmark.measure {
    api.update_all_buildings(campus_codes, buildings_codes)
  }
  puts "Update buildings Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_building_api.log for errors or warnings"

end
