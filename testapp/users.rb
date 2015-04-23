# -*- coding: utf-8 -*-

require_relative 'database_information'

class UsersAccessError < RuntimeError; end

class Userslist
  DEPS = [0, 1, 2]
  @@last_user = nil

  def self.this_id()
    @@last_user.id
  end
  def self.this_name()
    @@last_user.name
  end
  def self.this_depno()
    @@last_user.depno
  end
  def self.this_dep()
    dtos(@@last_user.depno)
  end
  def self.this_pass()
    @@last_user.path
  end
  def self.is_wrong_pass(db_pass, this_pass)
    db_pass != this_pass
  end
  def self.access(id, pass)
    u = User.find_by id: id
    if u == nil
      raise UsersAccessError.new("ID:#{id}は登録されていません。")
    elsif is_wrong_pass(u.pass, pass)
      raise UsersAccessError.new("パスワードが間違っています。")
    else
      @@last_user = u
    end
  end
  def self.get_ids()
    User.pluck(:id)
  end
  def self.get_names()
    User.pluck(:name)
  end
  def self.clear()
    User.destroy_all
    true
  end
  def self.include?(id)
    get_ids.include?(id)
  end
  def self.add(id, name, depno, pass)
    # u = User.new(id, name, depno, pass)
    u = User.new()
    u.id = id
    u.name = name
    u.depno = depno
    u.pass = pass
    @@last_user = u
    u.save
  end

  def self.list_depno()
    DEPS
  end
  def self.dtos(d)
    case d
    when 0
      "ITセキュリティ事業本部"
    when 1
      "総務部"
    else
      "その他"
    end
  end
end
