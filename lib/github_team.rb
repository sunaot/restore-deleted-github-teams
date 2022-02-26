class TeamNotFoundError < StandardError; end
class RepositoryAssignmentError < StandardError; end
class TeamMembershipError < StandardError; end

class GitHubTeam
  attr_reader :id, :name, :slug

  def initialize(organization, team_name, client)
    @client = client
    teams = @client.organization_teams(organization)
    result = teams.select {|team| team[:slug] == team_name }
    if result.empty?
      raise TeamNotFoundError
    end
    team = result.shift
    @id = team[:id]
    @name = team[:name]
    @slug = team[:slug]
    @parent = team[:parent]
  end

  # see https://docs.github.com/en/rest/reference/teams#add-or-update-team-repository-permissions
  # permission: { pull, push, admin, maintain, triage }
  def assign_repository(repository_path, permission: 'pull')
    result = @client.add_team_repository(@id, repository_path, permission: permission.to_s)
    unless result
      raise RepositoryAssignmentError.new("[repository_path]:(#{permission})")
    end
  end

  # see https://docs.github.com/en/rest/reference/teams#add-or-update-team-membership-for-a-user
  def join(username)
    begin
      result = @client.add_team_membership(@id, username)
    rescue Octokit::NotFound => e
      raise TeamMembershipError.new("[#{username}] #{e.message}")
    end
    unless result
      raise TeamMembershipError.new(username)
    end
  end
end
