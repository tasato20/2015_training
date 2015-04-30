# -*- coding: utf-8 -*-

require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'composite_primary_keys'
require 'date'

require 'csv'
require 'json'
require 'sinatra/contrib'
#require 'spreadsheet'

require_relative 'users'
require_relative 'departments'
require_relative 'timecards'
# require_relative 'timecards'

use Rack::Session::Cookie, :key => 'ams_session',
                          :expire_after => 86400

set :bind, '0.0.0.0'

get '/' do
  no = session[:no]
  if Users.get_name(no.to_i) != nil
    erb :userpage
  else
    erb :login
  end
end

get '/register' do
  erb :reg
end

post '/login' do
  p 'login session'
  no = params[:no]
  pass = params[:password]
  if Users.access(no,pass) == true
    p 'ok'
    session[:no] = no
    erb :userpage
  else
    p 'miss'
    erb :login
  end
end

post '/logout' do
  session[:no]=nil
  erb :login
end

post '/reg_finish' do 
  @new_no = params[:no]
  @new_name = params[:name]
  @new_department = params[:department]
  if Users.add(@new_no, @new_name,
                   @new_department, params[:pass])
    erb :reg_finish
  else
    erb :reg_error
  end
end

get '/admin' do
  erb :admin
end

post '/admin/department_registered' do
  @name = params[:name]
  if Departments.add(@name)
    @msg = "#{@name}を登録しました。"
  else
    @msg = "登録に失敗しました。"
  end
  erb :admin
end
post '/admin/department_changed' do
  @no = params[:no] 
  @new_name = params[:name]
  @old_name = Departments.name_of(@no)
  Departments.update(@no, @new_name)
  @msg = "#{@old_name}の名前を#{@new_name}に変更しました。"
  erb :admin
  #erb :admin_department_changed
end
post '/admin/department_deleted' do
  @no = params[:no]
  @name = Departments.name_of(@no)
  if Departments.remove(@no)
    @msg = "#{@name}を削除しました。"
  else
    @msg = "その部署に所属している人がいます。"
  end
  erb :admin
  #erb :admin_department_changed
end

post '/attend' do
#  @no = cookies[:no]
 # pass = cookies[:password]
  #accessresult = Users.access(@no,pass)
  @no = session[:no]

  @message = 
    if Users.get_name(@no.to_i) == nil
    #  accessresult
      "認証に失敗しました。"
    else
      time = (Time.now).strftime("%X")
      day = Date.today
      if params[:attend] != nil
        Timecard_operation.attend(day,@no,time)
      elsif params[:leave] != nil
        Timecard_operation.returnhome(day,@no,time)
      end  
    end
  
  erb :attend
end

post '/read-data' do
#  no = cookies[:no]
#  pass = cookies[:password]
  no = session[:no]
  if Users.get_name(no.to_i) != nil
    name = Users.get_name(no)
    department = Departments.name_of(Users.get_department(no))
    year = (Date.today).strftime("%Y")
    month = (Date.today).strftime("%m")
    timecards = Timecard_operation.read_monthly_data(no,"#{year}-#{month}")
    
    @msg = "#{no} <br>#{name} <br>#{department}<br><br>"
    n = 0
    
    for i in 1..30 do
      if timecards[n].day == Date::new(year.to_i,month.to_i,i)
        attend_time = (timecards[n].attendance).strftime("%X")
        if timecards[n].leaving != nil
          leave_time =  (timecards[n].leaving).strftime("%X")
        else
          leave_time = nil
        end
        @msg = @msg + "#{timecards[n].day} : #{attend_time} - #{leave_time} <br>"
        if n < timecards.length-1
          n = n+1
        end
      else
        @msg = @msg + "#{Date::new(year.to_i,month.to_i,i).to_s} : 出勤なし<br>"
      end
    end
    @message = @msg
    
 
    open("#{no}_#{year}#{month}timecards.json","w") do |io|
      JSON.dump(timecards.to_json,io)
    end
    
    @json_str = timecards.to_json
    
    erb :attend
  end
end

