//
//  Supabase.swift
//  Comeet
//
//  Created by Michael Ross on 2/9/24.
//  Copyright © 2024 Ice Cream Loaf. All rights reserved.
//

import Foundation
import Supabase

@Observable class Supabase {
    public var auth: AuthClient
    public var database: PostgrestClient
    public var storage: SupabaseStorageClient
    public var realtime: RealtimeClientV2
    public var functions: FunctionsClient
    
    public static var shared: Supabase {
        get {
            return Supabase()
        }
    }
    
    init() {
        let supabase = SupabaseClient(supabaseURL: URL(string: "https://bikoswjhsmcbwricdpyv.supabase.co")!, supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJpa29zd2poc21jYndyaWNkcHl2Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MDcyNjMzNjYsImV4cCI6MjAyMjgzOTM2Nn0.1JwCSopcavVJYNvAc9ya-L96Wf7zR508MvyZ02H6R_I")
        
        auth = supabase.auth
        database = supabase.database
        storage = supabase.storage
        realtime = supabase.realtimeV2
        functions = supabase.functions
    }
}
