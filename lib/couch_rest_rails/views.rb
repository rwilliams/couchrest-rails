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
      
        # Default to push all lists for the given database
        list_name = opts[:list_name] || '*'
      
        # Default to push all shows for the given database
        show_name = opts[:show_name] || '*'
      
        # Default to push all filters for the given database
        filter_name = opts[:filter_name] || '*'

        # Default to push all libs for the given database
        lib_name = opts[:lib_name] || '**/*.js'

        # Default to push all templates for the given database
        template_name = opts[:template_name] || '**/*'

        # Default to push all shows for the given database
        attachment_name = opts[:attachment_name] || '**/*'


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

          # Assemble shows for each design document
          shows = {}
          Dir.glob(File.join(designdoc, "shows", show_name)).each do |show|
            # Load show from filesystem 
            showfunc = IO.read(show)    if File.exist?(show)
            if showfunc.empty?
              response << "No show files were found in #{CouchRestRails.views_path}/#{db}/#{File.basename(designdoc)}/shows/#{File.basename(show)}.js" 
              next
            else
              shows[File.basename(show, '.js')] = showfunc
            end

            # Warn if overwriting shows on Couch 
            if couchdb_design_doc && couchdb_design_doc['shows'] && couchdb_design_doc['shows'][File.basename(show, '.js')]
              response << "Overwriting existing show '#{File.basename(show, '.js')}' in _design/#{File.basename(designdoc)}"
            end
          end
          # Merge with existing shows
	  if ! couchdb_design_doc.nil? && couchdb_design_doc.has_key?('shows')
            shows = couchdb_design_doc['shows'].merge!(shows)
          end

          # Assemble lists for each design document
          lists = {}
          Dir.glob(File.join(designdoc, "lists", list_name)).each do |list|
            # Load list from filesystem 
            listfunc = IO.read(list)    if File.exist?(list)
            if listfunc.empty?
              response << "No list files were found in #{CouchRestRails.views_path}/#{db}/#{File.basename(designdoc)}/lists/#{File.basename(list)}.js" 
              next
            else
              lists[File.basename(list, '.js')] = listfunc
            end

            # Warn if overwriting lists on Couch 
            if couchdb_design_doc && couchdb_design_doc['lists'] && couchdb_design_doc['lists'][File.basename(list, '.js')]
              response << "Overwriting existing list '#{File.basename(list, '.js')}' in _design/#{File.basename(designdoc)}"
            end
          end
          # Merge with existing lists
	  if ! couchdb_design_doc.nil? && couchdb_design_doc.has_key?('lists')
            lists = couchdb_design_doc['lists'].merge!(lists)
          end

          # Assemble filters for each design document
          filters = {}
          Dir.glob(File.join(designdoc, "filters", filter_name)).each do |filter|
            # Load filter from filesystem 
            filterfunc = IO.read(filter)    if File.exist?(filter)
            if filterfunc.empty?
              response << "No filter files were found in #{CouchRestRails.views_path}/#{db}/#{File.basename(designdoc)}/filters/#{File.basename(filter)}.js" 
              next
            else
              filters[File.basename(filter, '.js')] = filterfunc
            end

            # Warn if overwriting filters on Couch 
            if couchdb_design_doc && couchdb_design_doc['filters'] && couchdb_design_doc['filters'][File.basename(filter, '.js')]
              response << "Overwriting existing filter '#{File.basename(filter, '.js')}' in _design/#{File.basename(designdoc)}"
            end
          end
          # Merge with existing filters
	  if ! couchdb_design_doc.nil? && couchdb_design_doc.has_key?('filters')
            filters = couchdb_design_doc['filters'].merge!(filters)
          end

#------
          # deal with the lib scripts
          libs = {}
          # fetch an existing lib structure if it exists
          if couchdb_design_doc && couchdb_design_doc['libs'] 
            validate_doc_update = couchdb_design_doc['libs']
          end

          if File.exists?(File.join(designdoc, "libs")) && File.directory?(File.join(designdoc, "libs"))
            Dir.glob(File.join(designdoc, "libs", lib_name)).each do |lib|
                next if File.directory?(lib)
		name = lib.sub(File.join(designdoc, "libs") + "/", "")
                parts = name.split(/\//)
		file = File.basename(parts.pop, '.js')
		newnode = libs		# init for loop below
		parts.each do |dir|
			if ! newnode.has_key?(dir)
                        	newnode[dir] = {}	# init empty dir node
			end
			newnode = newnode[dir]		# descend
		end
		if newnode.has_key?(file)
                  response << "Overwriting existing library file #{name} in _design/#{File.basename(designdoc)}"
                end
		newnode[file] = IO.read(lib)		# newnode will be the proper place to put this.
            end
          end
#------
#------
          # deal with the templates
          templates = {}
          # fetch an existing templates structure if it exists
          if couchdb_design_doc && couchdb_design_doc['templates'] 
            validate_doc_update = couchdb_design_doc['templates']
          end

          if File.exists?(File.join(designdoc, "templates")) && File.directory?(File.join(designdoc, "templates"))
            Dir.glob(File.join(designdoc, "templates", template_name)).each do |template|
                next if File.directory?(template)
		name = template.sub(File.join(designdoc, "templates") + "/", "")
                parts = name.split(/\//)
		file = File.basename(parts.pop, '.html')
		newnode = templates		# init for loop below
		parts.each do |dir|
			if ! newnode.has_key?(dir)
                        	newnode[dir] = {}	# init empty dir node
			end
			newnode = newnode[dir]		# descend
		end
		if newnode.has_key?(file)
                  response << "Overwriting existing library file #{name} in _design/#{File.basename(designdoc)}"
                end
		newnode[file] = IO.read(template)		# newnode will be the proper place to put this.
            end
          end
#------

          # deal with the validate_doc_update script
          validate_doc_update = nil
          # fetch an existing validate doc if it exists
          if couchdb_design_doc && couchdb_design_doc['validate_doc_update'] 
            validate_doc_update =  couchdb_design_doc['validate_doc_update']
          end

          if File.exists?(File.join(designdoc, "validate_doc_update.js"))
            if validate_doc_update
              response << "Overwriting existing validate_doc_update in _design/#{File.basename(designdoc)}"
            end
            validate_doc_update = IO.read(File.join(designdoc, "validate_doc_update.js"))
          end


          # Save or update
          if couchdb_design_doc.nil?
            couchdb_design_doc = {
              "_id" => "_design/#{File.basename(designdoc)}", 
              'language' => 'javascript',
              'views' => views,
              'updates' => updates,
              'validate_doc_update' => validate_doc_update,
              'lists' => lists,
              'libs' => libs,
              'shows' => shows,
              'filters' => filters,
              'templates' => templates
            }
          else
            couchdb_design_doc['views'] = views
            couchdb_design_doc['updates'] = updates
            couchdb_design_doc['validate_doc_update'] = validate_doc_update
            couchdb_design_doc['lists'] = lists
            couchdb_design_doc['libs'] = libs
            couchdb_design_doc['shows'] = shows
            couchdb_design_doc['filters'] = filters
            couchdb_design_doc['templates'] = templates
          end
          db_conn.save_doc(couchdb_design_doc)

          response << "Pushed views to #{full_db_name}/_design/#{File.basename(designdoc)}: #{views.keys.join(', ')}"
          response << "Pushed updates to #{full_db_name}/_design/#{File.basename(designdoc)}: #{updates.keys.join(', ')}"
          response << "Pushed lists to #{full_db_name}/_design/#{File.basename(designdoc)}: #{lists.keys.join(', ')}"
          response << "Pushed shows to #{full_db_name}/_design/#{File.basename(designdoc)}: #{shows.keys.join(', ')}"
          response << "Pushed filters to #{full_db_name}/_design/#{File.basename(designdoc)}: #{filters.keys.join(', ')}"

          if File.exists?(File.join(designdoc, "attachments")) && File.directory?(File.join(designdoc, "attachments"))
            # re-fetch as a proper design doc in case it was new, otherwise file attachments will NOT work
            couchdb_design_doc = db_conn.get("_design/#{File.basename(designdoc)}") rescue nil

            Dir.glob(File.join(designdoc, "attachments", attachment_name)).each do |attachment|
                next if File.directory?(attachment)
		name = attachment.sub(File.join(designdoc, "attachments") + "/", "")
                couchdb_design_doc.put_attachment(name, IO.read(attachment))
            end
          end
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
