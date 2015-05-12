# -*- coding: utf-8 -*-

require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'date'

require 'csv'
require 'json'
require 'sinatra/contrib'
require 'erubis'
#require 'spreadsheet'

require_relative 'users'
require_relative 'departments'
require_relative 'timecards'
# require_relative 'timecards'
require_relative 'views/helpers/formutils'

use Rack::Session::Cookie, :key => 'ams_session',
                          :expire_after => 86400

set :bind, '0.0.0.0'
set :erb, :escape_html => true

get '/' do
  @user_id = session[:no]
  @name = Users.get_name(@user_id.to_i)
  if @name != nil
    erb :userpage
  else
    erb :login
  end
end

post '/login' do
  p 'login session'
  @user_id = params[:no]
  pass = params[:password]
  if Users.access(@user_id,pass) == true
    session[:no] = @user_id
    @name = Users.get_name(@user_id.to_i)
    erb :userpage
  else
    @msg = 'ログインに失敗しました'
    erb :login
  end
end

post '/logout' do
#  session[:no]=nil
  session.clear
  erb :login
end


get '/register' do
  erb :reg
end

post '/reg_finish' do
  @new_no = params[:no].to_i
  @new_name = params[:name]
  @new_department = params[:department].to_i
  if Users.add(@new_no,
               @new_name,
               @new_department,
               params[:pass])
    erb :reg_finish
  else
    erb :reg_error
  end
end

get '/admin' do
  erb :admin
end

post '/admin/register_department' do
  @name = params[:name]
  @succeed = Departments.add(@name)
  erb :register_department
end

post '/admin/change_department' do
  no = params[:no].to_i
  @new_name = params[:name]
  @old_name = Departments.name_of(no)
  @succeed = Departments.update(no, @new_name)
  erb :change_department
end

post '/admin/delete_department' do
  no = params[:no].to_i
  @name = Departments.name_of(no)
  @succeed = Departments.remove(no)
  erb :delete_department
end

post '/attend' do
  @user_id = session[:no]
  @name = Users.get_name(@user_id.to_i)

  if @name == nil
    @message = "認証に失敗しました。"
    erb :login
  else
    time = (Time.now).strftime("%X")
    day = Date.today
    @message = Timecard_operation.attend(day,@user_id,time)
    erb :attend_leave
  end
end


post '/leave' do
  @user_id = session[:no]
  @name = Users.get_name(@user_id.to_i)
  
  if @name == nil
    @message = "認証に失敗しました。"
    erb :login
  else
    time = (Time.now).strftime("%X")
    day = Date.today
    @message = Timecard_operation.returnhome(day,@user_id,time)
    erb :attend_leave
  end
end


post '/read-data' do
  @user_id = session[:no]
  if Users.get_name(@user_id) != nil
    @name = Users.get_name(@user_id)
    @department = Departments.name_of(Users.get_department(@user_id))
    year = (Date.today).strftime("%Y")
    month = (Date.today).strftime("%m")
    @json_str = Timecard_operation.read_monthly_data(@user_id, year, month)

    p @json_str
   
    erb :view_data
  end
end
