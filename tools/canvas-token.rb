# Make a Canvas API token for the site admin and print it as one line,
# TOKEN=<token>, on stdout. Everything else goes to stderr. Shared by
# deploy-test (CI), the staging inject scripts and tools/apply-example-course.sh.
#
#   docker compose exec -T -e TOKEN_PURPOSE="..." web \
#     bundle exec rails runner "$(cat tools/canvas-token.rb)" 2>runner.err | sed -n 's/^TOKEN=//p'
#
# Tokens with the same TOKEN_PURPOSE are replaced, so there is only ever one.
# It also turns on SIS imports, which `courses apply` needs (SWM-205).
#
# Why not just user.access_tokens.create!: on this Canvas image the site admin
# account's id comes back as a global id (10000000000002) while the row is id 2,
# so Canvas can't create its default developer key or its account bindings
# (foreign key errors), and tokens are then refused with 401 "Invalid access
# token". This creates both with local ids first. Safe to run again.

purpose = ENV.fetch("TOKEN_PURPOSE", "starWithMe tools")

begin
  Account.default.update!(allow_sis_import: true) if Account.default.respond_to?(:allow_sis_import=)
rescue => e
  warn "could not turn on SIS imports: #{e.class}: #{e.message.lines.first}"
end

key = DeveloperKey.default(create_if_missing: false)
if key.nil?
  key = DeveloperKey.new(name: "User-Generated")
  key.root_account_id = Account.site_admin.local_id
  key.save!(validate: false)
  Setting.set("User-Generated_developer_key_id", key.id.to_s)
  warn "created the default developer key"
end

[Account.site_admin, Account.default].each do |acct|
  next if DeveloperKeyAccountBinding.where(account_id: acct.local_id, developer_key_id: key.local_id, workflow_state: "on").exists?
  now = Time.now.utc
  DeveloperKeyAccountBinding.where(account_id: acct.local_id, developer_key_id: key.local_id).delete_all
  DeveloperKeyAccountBinding.insert_all!([{account_id: acct.local_id, developer_key_id: key.local_id,
    workflow_state: "on", root_account_id: acct.local_id, created_at: now, updated_at: now}])
  warn "turned the default developer key on for #{acct.name}"
end

user = Pseudonym.active.find_by!(unique_id: ENV.fetch("CANVAS_LMS_ADMIN_EMAIL")).user
user.access_tokens.active.where(purpose: purpose).each(&:destroy)
token = user.access_tokens.create!(purpose: purpose, developer_key: key)
puts "TOKEN=#{token.full_token}"
