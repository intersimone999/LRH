class IOAble
    def initialize
        @config = {}
    end
    
    def set_option(name, value)
        @config[name] = value
    end
    
    def get_option(name)
        return @config[name]
    end
    
    def debug!
        set_option :debug, true
        
        self
    end
    
    def debug?
        return get_option(:debug)
    end
    
    def job=(job)
        @job = job
    end
    
    def halt!
        @job.halt! if @job
    end
    
    def log(obj)
        msg = nil
        msg = "Lister: " + obj.to_s if self.is_a? Lister
        msg = "Runner: " + obj.to_s if self.is_a? Runner
        msg = "Harvester: " + obj.to_s if self.is_a? Harvester
        
        puts msg
        return msg
    end
end

class Lister < IOAble
    def initialize
        super
        @limit = false
    end
    
    def limit!(n)
        @limit = n
        
        self
    end
    
    def _list
        limit = @limit
        self.list do |e|
            yield e

            limit -= 1 if limit
            return if limit && limit <= 0
        end
    end
    
    def list
        list_array.each do |e|
            yield e
        end
        
        self
    end
    
    def list_array
        return []
    end
end

class ListerJoiner < IOAble
    def initialize
        super
    end
        
    def _join(lister_output)
        self.join(lister_output)
    end
    
    def join(lister_output)
        # Creates an instance 
    end
end

class InstanceJoiner < ListerJoiner
    def initialize(block)
        @block = block
    end
    
    def join(lister_output)
        return @block.call(lister_output)
    end
end

def joiner(&block)
    return InstanceJoiner.new(block)
end

class MultiLister < Lister
    def initialize(main_lister, joiner)
        @basic_lister = main_lister
        @joiner = joiner
    end
    
    def list
        @basic_lister.list do |basic_list_element|
            joined = @joiner.join(basic_list_element)
                
            joined.list do |sublist_element|
                yield sublist_element
            end
        end
    end
end

class ParallelLister < Lister
    def initialize(threads=4)
        super()
        @threads_number = threads
        @threads = []
    end
    
    def list
        queue = []
        done = false
        Thread.start do
            elements.each do |element|
                puts element
                while @threads.size == @threads_number
                    torem = []
                    @threads.each do |t|
                        torem.push t unless t.status
                    end
                    @threads -= torem
                    sleep 0.1
                end
                
                @threads.push Thread.start do 
                    list_one(element) do |target|
                        queue.push target
                    end
                end
            end
            done = true
        end
        
        while !done || queue.size > 0
            while queue.size == 0
                puts "Waiting..."
                sleep 0.1
            end
            
            yield queue.shift
        end
    end
    
    def elements
    end
    
    def list_one(element)
    end
end

class Runner < IOAble
    def initialize
        super
    end
    
    def _run(target)
        result = run(target)
        if debug?
            log result
        end
        
        return result
    end
    
    def _finally
        finally do |to_harvest|
            yield to_harvest
        end
    end
    
    def finally
    end
    
    def run(target)
        return nil
    end
end

class Harvester < IOAble
    def initialize
        super
    end
    
    def _harvest(partial)
        return harvest(partial)
    end
    
    def _result
        return result()
    end
    
    def harvest(partial)
    end
    
    def result
        return nil
    end
end

class Job
    NOT_RUNNING = 0
    RUNNING = 1
    HALTED = 2
    
    def initialize(lister, runner, harvester)
        @lister = lister
        @runner = runner
        @harvester = harvester
        
        @lister.job = self
        @runner.job = self
        @harvester.job = self
        
        @status = NOT_RUNNING
    end

    def run
        @status = RUNNING
        @lister._list do |target|
            partial = @runner._run(target)
            @harvester._harvest(partial)
            
            break if @status != RUNNING
        end
        
        @runner._finally do |to_harvest|
            @harvester._harvest(to_harvest)
        end
        
        @status = NOT_RUNNING
        
        return @harvester._result
    end
    
    def halt!
        @status = HALTED
    end
end

class PartialJob < Job
    def initialize(lister=NullLister.new, runner=NullRunner.new, harvester=NullHarvester.new)
        super
    end
end


###########################################
# STUBS
###########################################

class StubLister < Lister
    def initialize(spec={:time => Integer})
        @spec = spec
    end
    
    def rand_from_spec
        hash = {}
        
        @spec.each do |key, klass|
            if [Integer, Numeric].include? klass
                hash[key] = rand(10000)
            elsif String == klass
                hash[key] = (0...rand(100)).map { (('a'..'z').to_a + ('A'..'Z').to_a + ['!', '?', '/', '>', '<'])[rand(57)] }.join
            elsif Array == klass
                hash[key] = []
                rand(10).times do
                    hash[key].push (0...rand(100)).map { (('a'..'z').to_a + ('A'..'Z').to_a + ['!', '?', '/', '>', '<'])[rand(57)] }.join
                end
            else
                hash[key] = klass
            end
        end
        
        return hash
    end
    
    def list
        10.times do |i|
            yield rand_from_spec
        end
        
        self
    end
end

class StubRunner < Runner
    def run(target)
        return target
    end
end

class StubHarvester < Harvester
    def initialize
        @result = ""
    end
    
    def harvest(partial)
        @result += partial.to_s + "\n"
    end
    
    def result
        return @result
    end
end

class NullLister < Lister
    def list
    end
end

class NullRunner < Runner
    def run(target)
        return nil
    end
end

class NullHarvester < Harvester
    def harvest(partial)
    end
    
    def result
        return nil
    end
end

###########################################
# TEST RUNNER
###########################################
class LRHTest
    def self.test_job(lister, runner, harvester)
        job = Job.new(lister, runner, harvester)
        puts job.run
    end
    
    def self.test_lister(lister)
        self.test_job(lister, StubRunner.new, StubHarvester.new)
    end
    
    def self.test_runner(runner, listerOrSpec=StubLister.new)
        listerOrSpec = StubLister.new(listerOrSpec) unless listerOrSpec.is_a? Lister
        self.test_job(listerOrSpec, runner, StubHarvester.new)
    end
    
    def self.test_harvester(harvester, runner=StubRunner.new, listerOrSpec=StubLister.new)
        listerOrSpec = StubLister.new(listerOrSpec) unless listerOrSpec.is_a? Lister
        self.test_job(listerOrSpec, runner, harvester)
    end
end

def require_lister lname
    "require_relative \"listers/#{lname}\""
end

def require_runner rname
    "require_relative \"runners/#{rname}\""
end

def require_harvester hname
    "require_relative \"harvesters/#{hname}\""
end
