function make_structured_logs(tag, timestamp, record)
    -- Ensure fields exist and have a default value if missing
   local log_timestamp = record["time"] or record["timestamp"] or record["ts"] or record["date"] or os.date("!%Y-%m-%dT%H:%M:%SZ", timestamp)
   local level = record["level"] or "INFO"

   -- Determine 'source' field (caller or construction from fileds)
   local source = record["caller"] 
   if not source then
       local source_parts = {}
       if record["prefix"] then table.insert(source_parts, record["prefix"]) end
       if record["file"] then table.insert(source_parts, record["file"]) end
       if record["line"] then table.insert(source_parts, record["line"]) end
       if record["client_addr"] then table.insert(source_parts, record["client_addr"]) end
       if record["req_id"] then table.insert(source_parts, record["req_id"]) end
       if record["req_method"] then table.insert(source_parts, record["req_method"]) end
       if record["req_path"] then table.insert(source_parts, record["req_path"]) end
       if record["resp_bytes"] then table.insert(source_parts, record["resp_bytes"]) end
       if record["resp_duration"] then table.insert(source_parts, record["resp_duration"]) end
       if record["resp_status"] then table.insert(source_parts, record["resp_status"]) end
       source = table.concat(source_parts, "-")
   end

   if source == "" then
       source = "unknown"
   end

   local message = record["message"] or record["msg"]  or "No message"

   -- Construct a new record with fields in the desired order
   local ordered_record = {
       timestamp = log_timestamp,
       level = level,
       source = source,
       message = message
   }

   return 1, timestamp, ordered_record
end
