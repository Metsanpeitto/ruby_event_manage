require 'csv'
require 'google/apis/civicinfo_v2'
require 'erb'
require 'date'

def get_prime_day(registration_times)
   prime_day = nil
   days = []
   weekdays = []

   registration_times.each do |t|
     arr = t
     arr_date = arr[0]
     splitted = arr_date.split("/")
     month = splitted[0].to_i
     day = splitted[1].to_i
     year = 2000 + splitted[2].to_i
     d = Date.new(year,month,day)
     weekdays.push(d.cwday)    
   end    
   
   prime_day = weekdays.max_by {|w| weekdays.count(w)} 
   days = ["Monday", "Tuesday" , "Wednesday" , "Thursday", "Firday", "Saturday", "Sunday"] 
   weekday = days[prime_day -1]  
   return  weekday
end  


def get_prime_time(registration_times)  
   prime_time = nil
   hours = []
   registration_times.each do |time|
     arr_time = time[1].split(":")
     hours.push(arr_time[0])     
   end 

   prime_time = hours.max_by {|h| hours.count(h)} 
   return prime_time
end  



def clean_registration_time(regdate)  
  arr_time = regdate.split(" ")
  return  arr_time
end

def clean_phonenumber(phone) 
  digits = ["0","1","2","3","4","5","6","7","8","9"]
  arr_phone = phone.split("") 
  arr_phone_filtered = [] 
  phone_string = ""
  arr_phone.each do |n|
    if digits.include?(n)
      arr_phone_filtered.push(n)      
    end  
  end  

  if arr_phone_filtered.length == 10
    clean_phone = arr_phone_filtered
  elsif arr_phone_filtered.length == 11 
    clean_phone = arr_phone_filtered [1..11]
  end  
  
  if clean_phone
     phone_string = clean_phone.join("")      
  end  
  return phone_string
end

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5, '0')[0..4]
end

def legislators_by_zipcode(zip)
  civic_info = Google::Apis::CivicinfoV2::CivicInfoService.new
  civic_info.key = 'AIzaSyClRzDqDh5MsXwnCWi0kOiiBivP6JsSyBw'
   begin
   civic_info.representative_info_by_address(
        address: zipcode,
        levels: 'country',
        roles: ['legislatorUpperBody','legislatorLowerBody']
   ).officials
 
   rescue
     'You can find your representatives by visiting www.commoncause.org/take-action/find-elected-officials'
    end
end  


def save_thank_you_letter(id,form_letter)
    Dir.mkdir('output') unless Dir.exists?('output')    
    filename = 'output'
    FileUtils.mkdir_p(filename) unless File.exist?(filename) 
    File.open(File.join(filename, "thanks_#{id}.html"), 'w') do |file|
     file.puts form_letter
    end  
end  

puts "EventManager initialized"

contents = CSV.open('event_attendees.csv',
                     headers: true,
                     header_converters: :symbol
                    )

template_letter = File.read('form_letter.html')
erb_template = ERB.new template_letter                    

registration_times = []

contents.each do |row|
    id = row[0]
    name = row[:first_name]
    zipcode = clean_zipcode(row[:zipcode]) 
    phone = clean_phonenumber(row[:homephone])
    registration_time = clean_registration_time(row[:regdate])
    legislators = legislators_by_zipcode(zipcode)
    registration_times.push(registration_time)
    #personal_letter = template_letter.gsub('FIRST_NAME', name)
    #personal_letter.gsub!('LEGISLATORS', legislators)
    form_letter = erb_template.result(binding)
    save_thank_you_letter(id,form_letter)  
end  




# This is the Prime Time to start marketing campaings
#prime_time = get_prime_time(registration_times)
#prime_day = get_prime_day(registration_times)
def marketing_launch(registration_times)
  hour = get_prime_time(registration_times)
  day = get_prime_day(registration_times)
  puts "The Prime Time to launch our marketing campaign is on #{day} at #{hour} hours"
end   

marketing_launch(registration_times)
