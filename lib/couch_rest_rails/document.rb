module CouchRestRails
  class Document < CouchRest::ExtendedDocument

    include Validatable

    def self.use_database(db)
      db = [COUCHDB_CONFIG[:db_prefix], db.to_s, COUCHDB_CONFIG[:db_suffix]].join
      self.database = COUCHDB_SERVER.database(db)
    end
    
    def self.unadorned_database_name
      database.name.sub(/^#{COUCHDB_CONFIG[:db_prefix]}/, '').sub(/#{COUCHDB_CONFIG[:db_suffix]}$/, '')
    end

    # supplement the document class with methods that some rails extensions may expect
    # due to an assumption the model is inherited from ActiveRecord::Base
    def has_attribute?(attr_name)
      self.has_key?(attr_name.to_s)
    end
    
  end
end
