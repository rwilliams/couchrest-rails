module CouchRestRails
  module Views
    extend self

    # Push views to couchdb
    def push(database_name = '*', opts = {})
      
      CouchRestRails.process_database_method(database_name) do |db, response|
        
        full_db_name = [COUCHDB_CONFIG[:db_prefix], File.basename(db), COUCHDB_CONFIG[:db_suffix]].join
        full_db_path = [COUCHDB_CONFIG[:host_path], '/', full_db_name].join
        
        # Default to load from all design documents
        design_doc_name = opts[:design_doc_name] || '*'
        
        # Default to push all views for the given database
        view_name = opts[:view_name] || '*'
      
        # Default to push all updates for the given database
        update_name = opts[:update_name] || '*'
      
        # Check for CouchDB database
        if !COUCHDB_SERVER.databases.include?(full_db_name)
          response << "Database #{db} (#{full_db_name}) does not exist"
          next
        end
        
        # Check for views directory
        unless File.exist?(File.join(RAILS_ROOT, CouchRestRails.views_path, db))
          response << "Views directory (#{CouchRestRails.views_path}/#{db}) does not exist" 
          next
        end

	# connect to database        
        db_conn = CouchRest.database(full_db_path)

	# For each design doc seen
        Dir.glob(File.join(RAILS_ROOT, CouchRestRails.views_path, db, design_doc_name)).each do |designdoc|
          couchdb_design_doc = db_conn.get("_design/#{File.basename(designdoc)}") rescue nil

          # Assemble views for each design document
          views = {}
          Dir.glob(File.join(designdoc, "views", view_name)).each do |view|
            # Load view from filesystem 
            map_reduce = assemble_view(view)
            if map_reduce.empty?
              response << "No view files were found in #{CouchRestRails.views_path}/#{db}/#{File.basename(designdoc)}/views/#{File.basename(view)}" 
              next
            else
              views[File.basename(view)] = map_reduce
            end

            # Warn if overwriting views on Couch 
            if couchdb_design_doc && couchdb_design_doc['views'] && couchdb_design_doc['views'][File.basename(view)]
              response << "Overwriting existing view '#{File.basename(view)}' in _design/#{File.basename(designdoc)}"
            end

          end
          # Merge with existing views
	  if ! couchdb_design_doc.nil? && couchdb_design_doc.has_key?('views')
            views = couchdb_design_doc['views'].merge!(views)
          end

          # Assemble updates for each design document
          updates = {}
          Dir.glob(File.join(designdoc, "updates", update_name)).each do |update|
            # Load update from filesystem 
            upfunc = IO.read(update)    if File.exist?(update)
            if upfunc.empty?
              response << "No update files were found in #{CouchRestRails.views_path}/#{db}/#{File.basename(designdoc)}/updates/#{File.basename(update)}.js" 
              next
            else
              updates[File.basename(update, '.js')] = upfunc
            end

            # Warn if overwriting updates on Couch 
            if couchdb_design_doc && couchdb_design_doc['updates'] && couchdb_design_doc['updates'][File.basename(update, '.js')]
              response << "Overwriting existing update '#{File.basename(update, '.js')}' in _design/#{File.basename(designdoc)}"
            end
          end
          # Merge with existing updates
	  if ! couchdb_design_doc.nil? && couchdb_design_doc.has_key?('updates')
            updates = couchdb_design_doc['updates'].merge!(updates)
          end

          # Save or update
          if couchdb_design_doc.nil?
            couchdb_design_doc = {
              "_id" => "_design/#{File.basename(designdoc)}", 
              'language' => 'javascript',
              'views' => views,
              'updates' => updates
            }
          else
            couchdb_design_doc['views'] = views
            couchdb_design_doc['updates'] = updates
          end
          db_conn.save_doc(couchdb_design_doc)
          response << "Pushed views to #{full_db_name}/_design/#{File.basename(designdoc)}: #{views.keys.join(', ')}"
          response << "Pushed updates to #{full_db_name}/_design/#{File.basename(designdoc)}: #{updates.keys.join(', ')}"
        end	# loop on design doc
      end	# loop on databases
    end

    # Assemble views 
    def assemble_view(design_doc_path)
      view = {}
      map_file    = File.join(design_doc_path, 'map.js')
      reduce_file = File.join(design_doc_path, 'reduce.js')
      view[:map]    = IO.read(map_file)    if File.exist?(map_file)
      view[:reduce] = IO.read(reduce_file) if File.exist?(reduce_file) && File.size(reduce_file) > 0
      view
    end
    
  end
end
