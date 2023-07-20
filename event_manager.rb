require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, "0")[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'

  begin
    civic_info.representative_info_by_address(
      address: zip,
      levels: 'country',
      roles: ['legislatorUpperBody', 'legislatorLowerBody']
    ).officials
  rescue
    'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
  end
end

def clean_phone_number(phone_number)
  digits_only = phone_number.to_s.gsub(/\D/, '')

  if digits_only.length == 10
    # Good 10-digit number
    digits_only
  elsif digits_only.length == 11 && digits_only[0] == '1'
    # Trim the leading '1' for an 11-digit number
    digits_only[1..-1]
  else
    # Assume bad number for all other cases
    nil
  end
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir('output') unless Dir.exist?('output')

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
    file.puts form_letter
  end
end

puts 'Event Manager Initialized.'

contents = CSV.open(
  'event_attendees.csv',
  headers: true,
  header_converters: :symbol
)

template_letter = File.read('/Users/arieltyson/Desktop/event_manager/Event-Manager/form_letter.erb')
erb_template = ERB.new(template_letter)

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  zipcode = clean_zipcode(row[:zipcode])
  legislators = legislators_by_zipcode(zipcode)

  # Phone number validation
  phone_number = clean_phone_number(row[:phone])

  unless phone_number.nil?
  # Check and display the validity of phone number
    puts "Valid phone number: #{phone_number}"
  else
    puts "Invalid phone number: #{row[:phone]}"
  end

  # Time and day targeting
  registration_date_time = DateTime.strptime(row[:regdate], '%m/%d/%y %H:%M')
  registration_hour = registration_date_time.hour
  registration_day_of_week = registration_date_time.strftime('%A')

  puts "Registration Hour: #{registration_hour}"
  puts "Day of the Week: #{registration_day_of_week}"

  # The phone number and days will be generated in the terminal, the letters will be found in the output file.
  form_letter = erb_template.result(binding)
  save_thank_you_letter(id, form_letter)
end
