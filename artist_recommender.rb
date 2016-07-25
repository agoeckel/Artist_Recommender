require 'sqlite3'
require 'faker'

db = SQLite3::Database.new("artist_recommender.db")
db.results_as_hash = true

users_table = <<-SQL
  CREATE TABLE IF NOT EXISTS users(
    id INTEGER PRIMARY KEY,
    username VARCHAR(255),
    password VARCHAR(255)
  )
SQL

db.execute(users_table)

artists_table = <<-SQL
  CREATE TABLE IF NOT EXISTS artists(
    id INTEGER PRIMARY KEY,
    name VARCHAR(255),
    genre VARCHAR(255)
  )
SQL

db.execute(artists_table)

recommend_table = <<-SQL
  CREATE TABLE IF NOT EXISTS recommendations(
    id INTEGER PRIMARY KEY,
    username_id INTEGER,
    user_id INTEGER,
    artist_id INTEGER,
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (user_id) REFERENCES users(id),
    FOREIGN KEY (artist_id) REFERENCES artists(id)
  )
SQL

db.execute(recommend_table)


def drop_name(db, username)
  db.execute("DELETE FROM users WHERE username=(?)", [username])
end

def user_setup(db)
  puts "Please enter your username: "
  print '> '
  user_name = gets.chomp
  puts "Please enter your password: "
  print '> '
  password = gets.chomp
  db.execute("INSERT INTO users (username, password) VALUES (?, ?)", [user_name, password])
  user_name
end

def user_check(db, user_name, user_password)
  puts "Checking database......"
  users = db.execute("SELECT username, password FROM users")
  result = true
  users.each do |user|
    if (user.has_value?(user_name) == true) && (user.has_value?(user_password) == true)
      result = true
      break
    else
      result = false
    end
  end
  result
end

def user_recommendations(db, user_name)
  id = db.execute("SELECT id FROM users WHERE username=(?)", [user_name])
  num = id[0]["id"]
  display_recommendations = db.execute("SELECT * FROM recommendations WHERE user_id=(?)", [num])
  display_recommendations.each do |users|
    name = db.execute("SELECT username FROM users WHERE id=(?)", [users['username_id']])
    artist_name = db.execute("SELECT name FROM artists WHERE id=(?)", [users['artist_id']])
    puts "\n#{name[0]['username']} recommended you listen to #{artist_name[0]['name']}"
  end
  recommend_loop = true
  while recommend_loop
    puts "Make a recommendation? TYPE:(y/n)"
    response = gets.chomp.downcase
    if response == 'y'
      puts "FORMAT:(username, artist)"
      print '> '
      recommendation = gets.chomp
      split_answer = recommendation.split(", ")
      user = db.execute("SELECT * FROM users")
      user_result = true
      user_num = 0
        user.each do |name|
          user_num += 1
          if name["username"] == split_answer[0]
            user_result = true
            break
          else
            user_result = false
          end
        end
      artists = db.execute("SELECT * FROM artists")
      artist_result = true
      artist_num = 0
        artists.each do |name|
          artist_num += 1
          if name["name"] == split_answer[1]
            artist_result = true
            break
          else
            artist_result = false
          end
        end
      if user_result == true && artist_result == true
        puts "Making recommendation...."
        db.execute("INSERT INTO recommendations (username_id, user_id, artist_id) VALUES (?, ?, ?)", [num, user_num, artist_num])
      else
        puts "\nUSER OR ARTIST DOES NOT EXIST!"
      end
    else
      recommend_loop = false
    end
  end
end

def add_artist(db, name, genre)
  db.execute("INSERT INTO artists (name, genre) VALUES (?, ?)", [name, genre])
end

def list_artists(db)
  artists = db.execute("SELECT * FROM artists")
  names = artists.each do |artist|
    puts "\n#{artist["name"]} is specialized in #{artist["genre"]} type music."
  end
  names
end


#  genres = ['rap', 'classic', 'country', 'rock', 'alternative', 'hip-hop', 'r&b', 'wavey', 'deep house']
#   rand_genre = genres[rand(1..genres.length)]

# 100.times do
#   add_artist(db, Faker::Name.name, rand_genre = genres[rand(0..genres.length) -1])
# end


puts "WELCOME TO ARTIST RECOMMENDER"
puts "-" * 50
puts "Please enter your username: "
print '> '
user_name = gets.chomp
puts "Please enter your password: "
print '> '
password = gets.chomp
result = user_check(db, user_name, password)
if result == true
  puts "\nFOUND"
  puts "Logging in....."
  user_interface = true
else
  puts "NOT FOUND"
  puts "\nWould you like to create an account? TYPE:(y/n)"
  response = gets.chomp.downcase
  if response == "y"
    user_name = user_setup(db)
    user_interface = true
  else
    user_interface = false
  end
end

while user_interface
  puts "\nMENU || ARTISTS | RECOMMENDATIONS | (#{user_name})LOGOUT "
  puts "-" * 70
  print '> '
  user_input = gets.chomp.downcase
  case user_input
  when "logout"
    user_interface = false
  when "recommendations"
    user_recommendations(db, user_name)
  when "artists"
    list_artists(db)
  else
    puts "-Command not recognized-"
  end
end