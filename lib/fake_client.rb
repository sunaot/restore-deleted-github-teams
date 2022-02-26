require 'forwardable'

# Octokit::Client with no side effects
class FakeOctokit
  extend Forwardable

  def_delegators :@original_client, :organization_teams

  def initialize(client)
    @original_client = client
  end

  # https://github.com/octokit/octokit.rb/blob/4-stable/lib/octokit/client/organizations.rb#L516-L543
  def add_team_repository(team_id, repo, options = {})
    permission = options[:permission] || 'not specified'
    puts "[#{repo} > #{team_id}]:{#{permission}}"
    return true
  end

  # https://github.com/octokit/octokit.rb/blob/4-stable/lib/octokit/client/organizations.rb#L638-L651
  def add_team_membership(team_id, user)
    puts "[#{user} > #{team_id}]"
    return true
  end
end
