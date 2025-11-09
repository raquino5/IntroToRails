require 'faraday'
require 'json'
require 'faker'

RAWG_KEY = ENV.fetch("RAWG_API_KEY", nil)
RAWG_BASE = "https://api.rawg.io/api"
STEAM_BASE = "https://store.steampowered.com/api"

def get_json(url, params = {})
  resp = Faraday.get(url, params)
  JSON.parse(resp.body)
rescue => e
  puts "HTTP error: #{e.message}"
  {}
end

def slugify(str)
  str.to_s.downcase.gsub(/[^a-z0-9]+/,'-').gsub(/^-|-$/,'')
end

puts "Clearing old data..."
Review.delete_all
GameDeveloper.delete_all
GamePlatform.delete_all
GameGenre.delete_all
Developer.delete_all
Platform.delete_all
Genre.delete_all
Game.delete_all

# 1) Genres & Platforms & Developers from RAWG (paged)
if RAWG_KEY
  puts "Fetching genres..."
  genres = get_json("#{RAWG_BASE}/genres", { key: RAWG_KEY })["results"] || []
  genres.each do |g|
    Genre.find_or_create_by!(slug: g["slug"]) { |rec| rec.name = g["name"] }
  end

  puts "Fetching platforms..."
  plats = get_json("#{RAWG_BASE}/platforms", { key: RAWG_KEY })["results"] || []
  plats.each do |p|
    Platform.find_or_create_by!(slug: p["slug"]) { |rec| rec.name = p["name"] }
  end

  # Pull first 5 pages of popular games (enough to exceed 200 rows with joins & reviews)
  puts "Fetching games..."
  total_created = 0
  (1..5).each do |page|
    data = get_json("#{RAWG_BASE}/games", { key: RAWG_KEY, ordering: "-added", page: page, page_size: 40 })
    results = data["results"] || []
    break if results.empty?

    results.each do |g|
      next unless g["id"] && g["name"]
      slug = g["slug"] || slugify(g["name"])
      game = Game.find_or_initialize_by(rawg_id: g["id"])
      game.name = g["name"]
      game.slug = slug
      game.released = g["released"]
      game.rating = g["rating"]
      # RAWG description requires a separate call; use Faker fallback and we’ll augment later
      game.description = Faker::Lorem.paragraphs(number: 3).join("\n\n") if game.description.blank?
      game.save!

      # genres
      (g["genres"] || []).each do |gg|
        gen = Genre.find_by(slug: gg["slug"]) || Genre.create!(slug: gg["slug"], name: gg["name"])
        GameGenre.find_or_create_by!(game: game, genre: gen)
      end

      # platforms
      (g["platforms"] || []).each do |pp|
        p = pp["platform"]; next unless p
        plat = Platform.find_by(slug: p["slug"]) || Platform.create!(slug: p["slug"], name: p["name"])
        GamePlatform.find_or_create_by!(game: game, platform: plat)
      end

      # developers (need separate info endpoint)
      detail = get_json("#{RAWG_BASE}/games/#{slug}", { key: RAWG_KEY })
      (detail["developers"] || []).each do |dv|
        dev = Developer.find_or_create_by!(slug: dv["slug"]) { |rec| rec.name = dv["name"] }
        GameDeveloper.find_or_create_by!(game: game, developer: dev)
      end

      total_created += 1
    end
  end
  puts "Imported/updated RAWG games: #{total_created}"
else
  puts "No RAWG_API_KEY; seeding minimal Faker games for dev/testing..."
  60.times do
    name = Faker::Game.title
    Game.create!(
      name: name, slug: slugify(name),
      released: Faker::Date.between(from: '2005-01-01', to: Date.today),
      rating: rand(5.0..9.5).round(1),
      description: Faker::Lorem.paragraphs(number: 3).join("\n\n")
    )
  end
  %w[action rpg strategy indie sports simulation].each do |g|
    Genre.create!(name: g.capitalize, slug: g)
  end
  %w[pc playstation xbox switch mobile].each do |p|
    Platform.create!(name: p.capitalize, slug: p)
  end
  Game.find_each do |game|
    GameGenre.create!(game: game, genre: Genre.order("RANDOM()").first)
    GamePlatform.create!(game: game, platform: Platform.order("RANDOM()").first)
  end
  Developer.create!(name: "Indie Studio", slug: "indie-studio")
  Game.find_each { |g| GameDeveloper.find_or_create_by!(game: g, developer: Developer.first) }
end

# 2) Steam review snippets (no key needed for store userreviews)
def steam_app_details(appid)
  get_json("#{STEAM_BASE}/appdetails", { appids: appid.to_s })
end

def steam_search_appid_by_name(name)
  # Cheap heuristic: use Steam "supported" search API via Valve CDN isn’t public; fallback: none.
  nil
end

puts "Fetching Steam reviews (best-effort)…"
Game.limit(150).find_each do |game|
  appid = game.steam_appid || steam_search_appid_by_name(game.name)
  next unless appid

  resp = get_json("https://store.steampowered.com/appreviews/#{appid}", {
    json: 1, num_per_page: 20, purchase_type: "all"
  })
  next unless resp["success"]

  (resp["reviews"] || []).each do |r|
    content = r["review"].to_s.strip
    next if content.blank?
    Review.create!(
      game: game,
      author: (r["author"] && r["author"]["steamid"]) || "Steam user",
      content: content.truncate(800),
      source: "Steam",
      rating: r["voted_up"] ? 80 : 40
    )
  end
end

# 3) Faker top-ups: ensure 200+ rows overall
games_count = Game.count
genres_count = Genre.count
plats_count  = Platform.count
devs_count   = Developer.count
links = GameGenre.count + GamePlatform.count + GameDeveloper.count
puts "Counts -> games: #{games_count}, genres: #{genres_count}, platforms: #{plats_count}, devs: #{devs_count}, links: #{links}, reviews: #{Review.count}"

if Game.count < 80
  (80 - Game.count).times do
    name = Faker::Game.title
    g = Game.create!(
      name: name, slug: slugify(name),
      released: Faker::Date.between(from: '2008-01-01', to: Date.today),
      rating: rand(6.0..9.8).round(1),
      description: Faker::Lorem.paragraphs(number: 2).join("\n\n")
    )
    GameGenre.create!(game: g, genre: Genre.order("RANDOM()").first) if Genre.any?
    GamePlatform.create!(game: g, platform: Platform.order("RANDOM()").first) if Platform.any?
    GameDeveloper.create!(game: g, developer: Developer.order("RANDOM()").first) if Developer.any?
  end
end

puts "Seeding done."
