require 'pathname'
require 'csv'

# 事前条件)
#   id,event,timestamp 形式の csv を受け取り、
#   そのレコードは id -> timestamp の順で sort されていること

hisotry_filename = ARGV.shift
history_csv_path = Pathname.new(__dir__).join('..', 'audit_log', hisotry_filename)
unless history_csv_path.exist?
  raise "error: file not found [#{history_csv_path.to_s}]"
end

entries = {}

CSV.foreach(history_csv_path.to_s) do |row|
  id, event, timestamp = row
  entry = row.to_csv(row_sep: '')
  case event
  when 'team.add_member'
    unless entries.key?(id)
      entries.store(id, entry)
    else
      warn "team.add_member error: duplicate id [#{entry}"
    end
  when 'team.remove_member'
    if entries.key?(id)
      entries.delete(id)
    else
      warn "team.remove_member error: unknown id [#{id}]"
    end
  else
    raise "unknown event: [#{event}]"
  end
end

puts entries.keys

