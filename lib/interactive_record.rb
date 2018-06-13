require_relative "../config/environment.rb"
require 'active_support/inflector'
require 'pry'

class InteractiveRecord

  def self.table_name
    self.to_s.downcase.pluralize
  end

  def self.column_names
    sql = "PRAGMA table_info('#{table_name}')"
    column_array = DB[:conn].execute(sql)

    column_array.collect do |column|
      column["name"]
    end
  end

  def initialize(options={})
    options.each do |key, value|
      self.send("#{key}=", value)
    end
  end

  def table_name_for_insert
    self.class.table_name
  end

  def col_names_for_insert
    columns = self.class.column_names.delete_if {|column| column == "id"}
    columns.join(", ")
  end

  def values_for_insert
    columns_array = self.class.column_names.delete_if {|column| column == "id"}
    columns_array.map do |column|
      "'#{send(column)}'"
    end.join(", ")
  end

  def save
    sql = "INSERT INTO #{table_name_for_insert} (#{col_names_for_insert}) VALUES (#{values_for_insert})"

    DB[:conn].execute(sql)
    @id = DB[:conn].execute("SELECT last_insert_rowid()")[0][0]
  end

  def self.find_by_name(name)
    sql = "SELECT * FROM #{self.table_name} WHERE name = '#{name}'"

    DB[:conn].execute(sql)
  end

  def self.find_by(attribute)
    column = self.column_names.find do |column_name|
      [column_name.to_sym] == attribute.keys
    end

    sql = "SELECT * FROM #{self.table_name} WHERE #{column} = '#{attribute.values[0]}'"

    DB[:conn].execute(sql)
  end

end
