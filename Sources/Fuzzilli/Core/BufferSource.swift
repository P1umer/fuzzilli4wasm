//
//  BufferSource.swift
//  
//
//  Created by p1umer on 2020/2/26.
//
import Foundation

public class BufferSource: ComponentBase {
    
    private let maxCacheSize: Int
    private var caches: RingBuffer<[Int]>
    private var hit: Int
    private let samplePath: String
    
    public init(samplePath: String, maxCacheSize: Int) {
        self.samplePath = samplePath
        self.maxCacheSize = maxCacheSize
        self.hit = 0
        self.caches = RingBuffer(maxSize: maxCacheSize)
        super.init(name: "BufferSource")
    }
    
    override func initialize() {
        
        // Refresh when receive the signal BufferSourceCacheRefresh
        fuzzer.events.BufferSourceCacheRefresh.observe { event in
            self.refresh()
        }
        
        // Asynchronously refresh the caches
        fuzzer.events.BufferSourceCacheRefresh.dispatchAsync()
        
        // Schedule a timer to perform refresh regularly
        fuzzer.timers.scheduleTask(every: 30 * Minutes, refresh)
    }

    public var size: Int {
        return caches.count
    }

    public var isEmpty: Bool {
        return size == 0
    }
    
    /// Adds a buffeSource to the cache
    public func add(_ buffeSource: [Int]) {
        caches.append(buffeSource)
    }

    /// Adds multiple buffeSources to the cache
    public func add(_ buffeSources: [[Int]]) {
        buffeSources.forEach(add)
    }
    
    // Asynchronously refresh the caches if the hit count is greater than the caches count,
    // which means the repetition rate is too high
    public func refreshCheck() {
        if self.hit > caches.count && caches.count > 1 {
            fuzzer.events.BufferSourceCacheRefresh.dispatchAsync()
        }
    }
    
    /// Returns a random program from this caches and potentially increases  hit by one
    public func randomElement() -> [Int] {
//        if caches.isEmpty {
//            fuzzer.events.BufferSourceCacheRefresh.dispatch()
//            self.hit = 0
//        }
        self.hit += 1
        refreshCheck()
        let idx = Int.random(in: 0..<caches.count )
        let cache = caches[idx]
        return cache
    }
    
    // 1. Looking for the names of files which PATH includes
    // 2. Filter them with the wasm suffix
    // 3. Pick maxCacheSize samples at random
    public func selectFiles(path: String) -> [String] {
        do {
            let files = try FileManager.default.contentsOfDirectory(atPath: path)
            let filteredfiles = NSArray(array: files).pathsMatchingExtensions(["wasm"]).choose(self.maxCacheSize)
            return filteredfiles.map{ path+"/"+$0 }
        }
        catch {
            fatalError("Wasm files Path Not Exist")
        }
    }
    
    
    // Read bytes from the wasm files and ADD them to caches
    private func refresh() {
        let url = self.samplePath
        let files = selectFiles(path: url)
        do{
            try files.forEach { path in
                let data = try Data(contentsOf: URL(fileURLWithPath: path))
                var buffersource = [UInt8](data).map{ (byte) -> Int in
                    return Int(byte)
                }
                self.add(buffersource)
            }
        }
        catch {
            fatalError("Error when refresh caches")
        }
        self.hit = 0
        logger.info("BufferSource Caches refresh finished")
    }
}

extension Array {
    /// Returns an array containing this sequence shuffled
    var shuffled: Array {
        var elements = self
        return elements.shuffle()
    }
    /// Shuffles this sequence in place
    @discardableResult
    mutating func shuffle() -> Array {
        let count = self.count
        indices.lazy.dropLast().forEach {
            guard case let index = Int(arc4random_uniform(UInt32(count - $0))) + $0, index != $0 else { return }
            self.swapAt($0, index)
        }
        return self
    }
    func choose(_ n: Int) -> Array { return Array(shuffled.prefix(n)) }
}


