# Add crontask to server in order to run this at a specified time
#   run crontab -e
#================================
#   49 3 * * * /bin/bash -l -c 'cd /home/deployer/apps/vodsecurityproduction/current && RAILS_ENV=production /home/deployer/.rbenv/shims/bundle exec rake devicinator >> /home/deployer/apps/vodsecurityproduction/shared/log/cronstuff.log 2>&1'
#================================

# https://en.wikipedia.org/wiki/Cron
# https://medium.com/@pawlkris/scheduling-tasks-in-rails-with-cron-and-using-the-whenever-gem-34aa68b992e3

# The task will get info about all campuses 
# and update campus_records table in the database
# If campus is in the app db, but not in the API, a warning will be added to the log file

desc "This will update Classrooms database using APIs"
task api_update_database: :environment do

  # update campus list
  auth_token = AuthTokenApi.new("bf", "buildings")
  # auth_token "expires_in":3600 seconds
  result = auth_token.get_auth_token
  if result['success']
    access_token = result['access_token']
    total_time = 0
    api = BuildingsApi.new(access_token)
  else
    puts "No access_token. Error: " + result['error']
    exit
  end
  
  time = Benchmark.measure {
    api.update_campus_list
  }
  puts "Update campus list Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_campus_api.log for errors or warnings"

  # update buildings
  total_time += time.real.to_i
  if total_time > 3000
    auth_token = AuthTokenApi.new("bf", "buildings")
    result = auth_token.get_auth_token
    if result['success']
      total_time = 0
      access_token = result['access_token']
      api = BuildingsApi.new(access_token)
    else
      puts "No access_token. Error: " + result['error']
      exit
    end
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
  
  # api = BuildingsApi.new(access_token)
  time = Benchmark.measure {
    api.update_all_buildings(campus_codes, buildings_codes)
  }
  puts "Update buildings Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_building_api.log for errors or warnings"

  # update rooms
  total_time += time.real.to_i
  if total_time > 3000
    auth_token = AuthTokenApi.new("bf", "buildings")
    result = auth_token.get_auth_token
    if result['success']
      total_time = 0
      access_token = result['access_token']
      api = BuildingsApi.new(access_token)
    else
      puts "No access_token. Error: " + result['error']
      exit
    end
  end

  time = Benchmark.measure {
    api.update_rooms
  }
  puts "Rooms Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_room_api.log for errors or warnings"

  # add facility_id to classrooms and update instructional_seating_count
  auth_token = AuthTokenApi.new("aa", "classrooms")
  result = auth_token.get_auth_token
  if result['success']
    total_time = 0
    access_token = result['access_token']
    api = ClassroomApi.new(access_token)
  else
    puts "No access_token. Error: " + result['error']
    exit
  end

  time = Benchmark.measure {
    api.add_facility_id_to_classrooms(campus_codes, buildings_codes)
  }
  puts "Add FacilityID for classroom Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_facility_id_logger_api.log for errors or warnings"

  # update classrooms characteristics
  total_time += time.real.to_i
  if total_time > 3000
    auth_token = AuthTokenApi.new("aa", "classrooms")
    result = auth_token.get_auth_token
    if result['success']
      total_time = 0
      access_token = result['access_token']
      api = ClassroomApi.new(access_token)
    else
      puts "No access_token. Error: " + result['error']
      exit
    end
  end

  time = Benchmark.measure {
    api.update_all_classroom_characteristics
    UpdateRoomCharacteristicsArrayJob.perform_now
  }
  puts "Update classroom characteristics Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_classroom_characteristics_api.log for errors or warnings"
  
  # update classrooms contacts
  total_time += time.real.to_i
  if total_time > 3000
    auth_token = AuthTokenApi.new("aa", "classrooms")
    result = auth_token.get_auth_token
    if result['success']
      total_time = 0
      access_token = result['access_token']
      api = ClassroomApi.new(access_token)
    else
      puts "No access_token. Error: " + result['error']
      exit
    end
  end

  time = Benchmark.measure {
    api.update_all_classroom_contacts
  }
  puts "Update classroom contacts Time: #{time.real.round(2)} seconds"
  puts "See the log file #{Rails.root}/log/#{Date.today}_classroom_contact_api.log for errors or warnings"

end
