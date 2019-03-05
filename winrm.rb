#!/usr/bin/ruby
# -*- encoding : utf-8 -*-
"""
Dependencies:
https://github.com/WinRb/WinRM
gem install -r winrm

https://github.com/WinRb/winrm-fs
gem install -r winrm-fs

https://github.com/jarilaos/winrm

by Laox

"""
require 'winrm'
require 'winrm-fs'
require 'readline'

opts = { 
  endpoint: 'http://IP:5985/wsman',
  user: 'hostname\user',
  password: 'PASSWORD'
}


# Config for SSL
# opts = { 
#   endpoint: 'https://IP:5986/wsman',
#   transport: :ssl,
#   client_cert: 'certnew.cer',
#   client_key: 'client.key',
#   no_ssl_peer_verification: true,
# }

class String
  def tokenize
    self.
      split(/\s(?=(?:[^'"]|'[^']*'|"[^"]*")*$)/).
      select {|s| not s.empty? }.
      map {|s| s.gsub(/(^ +)|( +$)|(^["']+)|(["']+$)/,'')}
  end
end

# For autocomplete commands with TAB
# TODO use both methods
# LIST = [
#   'upload', 'download', 'exit', 'Get-Content','Invoke-Command',
#   'Invoke-Expression','Get-Process','New-Object','Invoke-WebRequest'
# ].sort

# Readline.completion_proc = proc do |input|
#   LIST.select { |name| name.start_with?(input) }
# end

#For autocomplete file names on local machine with TAB 
Readline.completion_append_character = " "
Readline.completion_proc = Proc.new do |str|
 Dir[str+'*'].grep(/^#{Regexp.escape(str)}/)
end

#Ignores pressing ^C
#trap("INT", "SIG_IGN")

pwd=""
begin
  conn = WinRM::Connection.new(opts)

  file_manager = WinRM::FS::FileManager.new(conn) 
  conn.shell(:powershell) do |shell|
  #If target is blocking powershell use cmd
  #conn.shell(:cmd) do |shell|  
    #Full path
    pwd = shell.run('cmd /c cd').output.strip
    #Only current folder
    #pwd = shell.run('(gi $pwd).Name').output.strip
    while command = Readline.readline("PS "+pwd+"> ", true)#true for command history
        if command.eql? "exit"
          break
        
        elsif command.start_with?('upload')     
          upload_command = command.tokenize
          if upload_command.length < 3
            upload_command[2] = '.'
          end          
          print("Uploading " + upload_command[1] + " to " + upload_command[2])
          file_manager.upload(upload_command[1], upload_command[2]) do |bytes_copied, total_bytes, local_path, remote_path|
            puts(" #{bytes_copied} bytes of #{total_bytes} bytes copied")
          end
        
        elsif command.start_with?('download')
          download_command = command.tokenize
          if download_command.length < 3
            download_command[2] = download_command[1]
          end
          print("Downloading " + download_command[1] + " to " + download_command[2])
          file_manager.download(download_command[1], download_command[2]) do |bytes_copied, total_bytes, local_path, remote_path|
            puts(" #{bytes_copied} bytes of #{total_bytes} bytes copied")
          end
          print("\nexec dos2unix "+download_command[2]+" to read properly\n")
        
        else
          shell.run(command) do |stdout, stderr|
            STDOUT.print stdout
            STDERR.print stderr
          end
          #Reload current folder only if it changes
          if command.include? "cd " 
            #Full path
            pwd = shell.run('cmd /c cd').output.strip
            #Only current folder
            #pwd = shell.run('(gi $pwd).Name').output.strip
          end
        end
    end
  end
rescue Interrupt => e
  print "\n"
end