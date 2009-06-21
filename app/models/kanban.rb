class Kanban
  attr_accessor :incoming_issues
  attr_accessor :quick_issues
  attr_accessor :backlog_issues
  attr_accessor :settings
  
  def self.find
    kanban = Kanban.new
    kanban.settings = Setting.plugin_redmine_kanban
    kanban.incoming_issues = kanban.get_incoming_issues
    kanban.quick_issues = kanban.get_quick_issues
    kanban.backlog_issues = kanban.get_backlog_issues(kanban.quick_issues.values.flatten.collect(&:id))
    kanban
  end

  def get_incoming_issues
    return Issue.visible.find(:all,
                              :limit => @settings['panes']['incoming']['limit'],
                              :order => "#{Issue.table_name}.created_on ASC",
                              :conditions => {:status_id => @settings['panes']['incoming']['status']})
  end

  def get_backlog_issues(exclude_ids=[])
    issues = Issue.visible.all(:limit => @settings['panes']['backlog']['limit'],
                               :order => "#{Issue.table_name}.created_on ASC",
                               :include => :priority,
                               :conditions => ["#{Issue.table_name}.status_id IN (?) AND #{Issue.table_name}.id NOT IN (?)", @settings['panes']['backlog']['status'], exclude_ids])

    return issues.group_by {|issue|
      issue.priority
    }.sort {|a,b|
      a[0].position <=> b[0].position # Sorted based on IssuePriority#position
    }
  end

  # TODO: similar to backlog issues
  def get_quick_issues
    issues = Issue.visible.all(:limit => @settings['panes']['quick-tasks']['limit'],
                               :order => "#{Issue.table_name}.created_on ASC",
                               :include => :priority,
                               :conditions => {:status_id => @settings['panes']['backlog']['status'], :estimated_hours => nil})

    return issues.group_by {|issue|
      issue.priority
    }.sort {|a,b|
      a[0].position <=> b[0].position # Sorted based on IssuePriority#position
    }
  end

  def quick_issue_ids
    return @quick_issues.values.flatten.collect(&:id)
  end
end
