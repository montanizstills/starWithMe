# Set the local Canvas site admin's password (SWM-228). Run by
# tools/rotate-admin-password.sh, never by hand:
#
#   printf '%s\n%s\n' "$new" "$old" | docker compose exec -T web \
#     bundle exec rails runner "$(cat tools/canvas-admin-password.rb)"
#
# The new and old passwords come in on stdin (line 1 and line 2), so they are
# never in a command line, an environment variable or a log. The admin is the
# pseudonym for CANVAS_LMS_ADMIN_EMAIL, the same one tools/canvas-token.rb uses.
#
# Prints one line on stdout: ROTATED when the new password works and the old
# one no longer does, otherwise ERROR=<reason>. The reason never holds a value.

new_pw, old_pw = $stdin.read.to_s.split("\n").map(&:strip)
new_pw = new_pw.to_s
old_pw = old_pw.to_s

begin
  raise ArgumentError, "the new password is empty" if new_pw.empty?
  raise ArgumentError, "the new password is the same as the old one" if new_pw == old_pw

  pseudonym = Pseudonym.active.find_by!(unique_id: ENV.fetch("CANVAS_LMS_ADMIN_EMAIL"))
  pseudonym.password = new_pw
  pseudonym.password_confirmation = new_pw
  pseudonym.save!
  pseudonym.reload

  if !pseudonym.valid_password?(new_pw)
    puts "ERROR=Canvas saved the password but does not accept it"
  elsif !old_pw.empty? && pseudonym.valid_password?(old_pw)
    puts "ERROR=Canvas still accepts the old password"
  else
    puts "ROTATED"
  end
rescue ActiveRecord::RecordInvalid => e
  # Validation messages name the rule (too short, too common), not the value
  puts "ERROR=Canvas refused the password: #{e.record.errors.full_messages.join('; ')}"
rescue => e
  puts "ERROR=#{e.class}"
end
