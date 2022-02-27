Redmine::Plugin.register :new_features do
  name 'New Features plugin'
  author 'Author name'
  description 'This is a plugin for Redmine'
  version '0.0.1'
  Redmine::WikiFormatting::Macros.register do
    macro :timelog_table do |obj,args|
	    return '' if obj.blank?
	    project = obj.is_a?(Issue) ? obj.project : obj.issue.project
	    activity = TimeEntryActivity.where(name: 'Internal training').first
	    time_entries = project.time_entries.where.not(activity_id: activity.try(:id)).group_by(&:user)
      html = "<table><th>User Name</th><th>Issue</th><th>Title</th><th>Total time</th>"
      time_entries.each do |user, entries|
	      entry_group = entries.group_by(&:issue)
	      entry_group.each do |issue, issue_entries|
		      html += "<tr><td>#{user.name}</td><td>#{issue.id}</td><td>#{issue.subject}</td><td>#{issue_entries.pluck(:hours).compact.sum}</td></tr>"
	      end
      end
      html += "</table>"
      html.html_safe
    end
  end
end
