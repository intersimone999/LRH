# LRH
This is a very simple script that implements a Lister-Runner-Harvester framework in Ruby.

## Overview
Why should you use LRH? Because it allows you to better organize your data analysis scripts and it allows you to reuse components
very easily. For example, you have to do create two scripts: the first one exports a CSV with the number of lines of all the files in a
folder and the second one exports a CSV with the last modified date of the same files. In this case, you would create a single lister and
a single harvester for both the scripts and you just need a different runner for each of them. If in the future you need to get those
stats only for files with a certain name patter, you just create a new lister, and you can use it for both the scripts.

### Lister
A lister enumerates elements, of any type. A lister can, for example, enumerate folders, files or XML nodes.

### Runner
A runner is executed for each element enumerated by the lister. It represents a basic operation. A runner can, for example, 
change the name of a file or add an attribute to specific XML nodes.

### Harvester
A harvester collects all the results of all the runners and exports them in a specific format. A harvester can, for example, 
collect information about the file length and export them in CSV.

### Job
A job requires a lister, a runner and a harvester. It makes the lister enumerate the elements; for each element it calls the runner
to get the results and, in pipeline, the harvester to collect the results. Finally, it asks the harvester to export the results.


## How to use it
Clone the repository and add the folder in your require path. A gem will be available soon. Then, just add the require instruction
in your script:

`require "LRH.rb"`

### Defining a lister
A lister has this structure:
```
class ListAllCharacters < Lister
    def initialize(opt1)
        super()
        #Saves the option. This is not necessary, your lister coud have no constructor at all.
        set_option :string, opt1
    end

    # Main method. It yields an element.
    def list
        string     = get_option :string
        
        #Assuming that opt1 is a string, it gets all the caracter and it iterates a character at a time
        string.split("").each do |chr|
            yield chr
        end
    end
end
```

The only method you need to implement is `list`.

### Defining a runner
A runner has this structure:
```
class CountACharacter < Runner
    def initialize(char_to_count)
        super()
        set_option :ctc, char_to_count
    end
    
    # Executes an operation for each element yielded by the "list" method of a lister
    def run(target)
        ctc = get_option :ctc
        
        if target == ctc
            #Data that have to be collected by the harvester
            return 1
        else
            #Data that have to be collected by the harvester
            return 0
        end
    end
 end
```

You just need to implement the method `run(target)`.

### Defining a harvester
A harvester has this structure:
```
class CollectCharacterNumber < Harvester
    def initialize()
        super()
        @count = 0
    end
    
    # Collects partial data returned by the runner
    def harvest(partial)
        @count += partial
    end

    # Action executed when all the listed element have been processed
    def result
        puts "Total number of instances: #@count"
    end
end
```


