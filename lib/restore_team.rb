require 'octokit'
require 'yaml'
require_relative 'github_team'
require_relative 'fake_client'

team_slug, mode, list_filename, organization, token_slug, confirmed = ARGV

# credentials
config = YAML::load_file('.github/credentials')
credentials = config.fetch(token_slug)

# client
octokit = Octokit::Client.new(access_token: credentials['token'])
fake = FakeOctokit.new(octokit)
Octokit.auto_paginate = true
client = confirmed == 'RUN' ? octokit : fake

# repos/members list
targets = File.open(list_filename, 'r') do |f|
  f.readlines(chomp: true)
end

team = GitHubTeam.new(organization, team_slug, client)

case mode.to_sym
when :member
  targets.each do |member|
    begin
      team.join(member)
    rescue TeamMembershipError => e
      warn "error: #{e.message}"
    end
  end
when :repos, :repo, :repository
  targets.each do |repo|
    name, permission = repo.split(',')
    begin
      team.assign_repository(name, permission: permission)
    rescue RepositoryAssignmentError => e
      warn "error: #{e.message}"
    end
  end
else
  warn "unknown command: [#{mode}]"
end


