#!/usr/bin/env ruby

require 'sinatra'
require 'sinatra/reloader' if development?
require 'bcrypt'
require 'sqlite3'

set :show_exceptions, :after_handler
enable :sessions

db = SQLite3::Database.new 'db/test.db'
db.execute <<-SQL
	create table if not exists users (
		username varchar(64),
		password varchar(64)
	)
SQL

def component name, hash = {}
	erb name, views: settings.root + '/views/components', locals: hash
end

get '/' do
	if session[:username]
		erb :app
	else
		erb :index
	end
end

get '/signup' do
	erb :signup
end

post '/signup' do
	username = params['username']
	password = BCrypt::Password.create params['password']

	# make sure user doesn't already exist
	exists = false
	db.execute 'select * from users where username = ?', [username] do
		halt erb :signup, locals: {err: "User '#{username}' already exists"}
	end

	db.execute 'insert into users values (?, ?)', [username, password]

	session[:username] = username
	redirect to '/login'
end

get '/login' do
	erb :login
end

post '/login' do
	username = params['username']
	password = params['password']

	db.execute 'select * from users where username = ?', [username] do |row|
		p row
		if BCrypt::Password.new(row[1]) == password
			session[:username] = username
			redirect to '/'
		end
		halt erb :login, locals: {err: "Incorrect user or password"}
	end
end

