#P3
#Group Members: JohnBrinker, Ryan Sachs


require 'socket'

$port = nil             # Port number for the node's server to listen for TCP connections
$hostname = nil         # Node's hostname - unique identifier
$allPorts = {}          # Data structure that houses the port numbers of all the available machines
$running = false        # Boolean to keep track of whether or not the node is still running
$mainThread = nil       # Main Thread (reading STDIN)
$tcpThread = nil        # TCP Thread (handling sockets)
$routingTable = {}      # Data structure for the distance/nextHop for certain nodes
$allClients = {}        # Data structure for the client objects
$socketProcessing = false
$neighbors = []


# --------------------- Part 0 --------------------- #

def edgeb(cmd)
    
    #Extract command line arguments
    sourceIP = cmd[0]
    destinationIP = cmd[1]
    destination = cmd[2]
    
    #Create initial entry in this node's routing table for destination
    addRoutingEntry($hostname,destination,destination,1)
    STDOUT.flush
    
    #Create TCP connection with DST node, and send command to create edge
    STDOUT.flush
    sock = TCPSocket.new(destinationIP, $allPorts[destination])
    sock.write "MAKEEDGE " + $hostname + " 1"; 
    sock.close
    
    STDOUT.flush
    
end

def dumptable(cmd)
    
    sleep(1)
    
    #Extract command line arguments
    filename = cmd[0]
    
    #Open file
    file = File.open(filename,'w');
    
    #Create array lines[], add each entry in routing table
    lines = []
    $routingTable.each do |key, array|
        #"SRC,DEST,NextHop,Distance"
        source = array[0]
        destination = array[1]
        nextHop = array[2]
        distance = array[3]
    end
    
    #Join the entries of lines[] with newline, and write it to the file
    file.write(lines.join("\n"))
    file.close
    
end

def shutdown(cmd)
    #Set running variable to show the process is being shutdown
    $running = false;
    
    #Kill the tcpThread
    Thread.kill($tcpThread)

    #Flush all pending write buffers (stdout, stderr, files)
    STDOUT.flush
    STDERR.flush
    
    $allClients.each do |c|
        c.close
    end
    
    exit(0)
end

# --------------------- Part 1 --------------------- #
def edged(cmd)
    destination = cmd[0]
    deleteRoutingEntry(destination)
end

def edgeu(cmd)
    destination = cmd[0]
    weight = cmd[1]
    updateRoutingEntry(destination,weight)
end

def status()
    STDOUT.puts "Name: #{$hostname} Port: #{$port} Neighbors: #{$neighbors.sort}"
    STDOUT.flush
end


# --------------------- Part 2 --------------------- #
def sendmsg(cmd)
    STDOUT.puts "SENDMSG: not implemented"
end

def ping(cmd)
    STDOUT.puts "PING: not implemented"
end

def traceroute(cmd)
    STDOUT.puts "TRACEROUTE: not implemented"
end

def ftp(cmd)
    STDOUT.puts "FTP: not implemented"
end

# --------------------- Part 3 --------------------- #
def circuit(cmd)
    STDOUT.puts "CIRCUIT: not implemented"
end




# ---------------- Helper Functions ---------------- #

def addRoutingEntry(source,destination,nextHop,distance)
    #Using destination node as key, insert routing entry
    $routingTable[destination] = [source,destination,nextHop,distance]
    $neighbors += [destination]
    STDOUT.flush
end

def deleteRoutingEntry(destination)
    $routingTable.delete(destination)
    $neighbors -= [destination]
end

def updateRoutingEntry(destination,distance)
    temp = $routingTable[destination]
    temp[3] = distance
    $routingTable[destination] = temp
end


### First function run - sets up ports, server, buffers, etc

def setup(hostname, port, nodes, config)
    $hostname = hostname
    $port = port
    $socketProcessing = false
    
    #set up ports, server, buffers
    
    #Read in node file
    fileObj = File.new(nodes,"r")
    while(line = fileObj.gets)
        line.strip()
        args = line.split(',')
        $allPorts[args[0]] = args[1].to_i
    end
    
    STDOUT.flush
    #Set global running variable to true
    $running = true
    
    STDOUT.flush
    
    #Starts 2 threads - one for listening for incoming connections, and the other for the main
    $tcpThread=Thread.new{startListening()}
    $mainThread=Thread.new{main()}
    
    #Wait for the main thread to join - then kill the server thread
    $mainThread.join()
    $tcpThread.join()
    
end


### Main Function - loops reading STDIN ###
def main()
    
    sleep(1)
    
    STDOUT.flush
    
    while(line = STDIN.gets())
        line = line.strip()
        arr = line.split(' ')
        cmd = arr[0]
        args = arr[1..-1]
        STDOUT.flush
        case cmd
            when "EDGEB"; edgeb(args)
            when "EDGED"; edged(args)
            when "EDGEU"; edgeu(args)
            when "DUMPTABLE"; dumptable(args)
            when "SHUTDOWN"; shutdown(args)
            when "STATUS"; status()
            when "SENDMSG"; sendmsg(args)
            when "PING"; ping(args)
            when "TRACEROUTE"; traceroute(args)
            when "FTP"; ftp(args)
            when "CIRCUIT"; circuit(args)
        end
        
    end
    
end


### TCP Listener - loops and listens for incoming TCP socket connections
def startListening
    
    # Create a new server, listening on $port
    server = TCPServer.new $port
    
    STDOUT.flush
    
    $socketProcessing = true
    
    # Loop listening for incoming connections
    loop do
        
        #Accepted connection
        client = server.accept
        $allClients += client
        
        STDOUT.flush
        
        #Read messages from client
        while line=client.gets
            STDOUT.flush
            line = line.strip()
            arr = line.split(' ')
            STDOUT.flush
            case arr[0]
                when "MAKEEDGE";addRoutingEntry($hostname,arr[1],arr[1],arr[2])
            end
        end
        
        #Close client
        $allClients -= client
        client.close
        
        
    end
    
    $socketProcessing = false
    
    STDOUT.flush
    
end


#Initial call to setup using the command line arguments
setup(ARGV[0], ARGV[1], ARGV[2], ARGV[3])