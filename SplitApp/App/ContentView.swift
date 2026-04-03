import SwiftUI

struct ContentView: View {

    var body: some View {
        EventsFlowView()
    }
}


    @State private var username: String = ""
    @State private var phoneNumber: String = ""
    
    @State private var createdEvent: EventDTO?
    @State private var errorMessage: String?
    @State private var isLoading: Bool = false
    @State private var isShowingLocalData: Bool = false
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDUser.name, ascending: true)],
        animation: .default)
    private var localUsers: FetchedResults<CDUser>

    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDEvent.createdAt, ascending: false)],
        animation: .default)
    private var localEvents: FetchedResults<CDEvent>
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Create User & Event")) {
                    TextField("Username", text: $username)
                        .textContentType(.name)
                    
                    TextField("Phone Number", text: $phoneNumber)
                        .keyboardType(.phonePad)
                        .textContentType(.telephoneNumber)
                    
                    Button {
                        createTestFlow()
                    } label: {
                        if isLoading {
                            ProgressView()
                        } else {
                            Text("Submit")
                        }
                    }
                    .disabled(username.isEmpty || phoneNumber.isEmpty || isLoading)
                }
                
                if let errorMessage {
                    Section {
                        Text(errorMessage)
                            .foregroundColor(.red)
                    }
                }
                
                if let event = createdEvent {
                    Section(header: Text("Created Event (Backend)")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("**ID:** \(event.id)")
                            Text("**Name:** \(event.name)")
                            Text("**Creator ID:** \(event.creatorId)")
                            Text("**Status:** \(event.isClosed ? "Closed" : "Open")")
                            Text("**Created At:** \(event.createdAt.formatted())")
                        }
                        .font(.caption)
                    }
                }
                
                Section {
                    Button(isShowingLocalData ? "Hide Local Data" : "Show Local DB Data") {
                        withAnimation {
                            isShowingLocalData.toggle()
                        }
                    }
                }
                
                if isShowingLocalData {
                    LocalDataComponent(users: localUsers, events: localEvents)
                }
            }
            .navigationTitle("Network Test")
        }
    }
    
    private func createTestFlow() {
        isLoading = true
        errorMessage = nil
        createdEvent = nil
        
        Task {
            do {
                // 1. Create User
                let userReq = CreateUserRequest(name: username, phoneNumber: phoneNumber)
                let user = try await APIClient.shared.createUser(userReq)
                
                // 2. Create Event for that user
                let eventReq = CreateEventRequest(creatorId: user.id, name: "\(user.name)'s Party")
                let event = try await APIClient.shared.createEvent(eventReq)
                
                // 3. Save to Local DB
                try await CoreDataStore.shared.performBackground { context in
                    try CoreDataStore.shared.upsertUser(user, in: context)
                    try CoreDataStore.shared.upsertEvent(event, in: context)
                }
                
                await MainActor.run {
                    self.createdEvent = event
                    self.isLoading = false
                }
            } catch {
                await MainActor.run {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                }
            }
        }
    }
}

struct LocalDataComponent: View {
    var users: FetchedResults<CDUser>
    var events: FetchedResults<CDEvent>
    
    var body: some View {
        if !users.isEmpty {
            Section(header: Text("Local DB: Users")) {
                ForEach(users) { user in
                    VStack(alignment: .leading) {
                        Text(user.name ?? "Unknown").font(.headline)
                        Text(user.phoneNumber ?? "").font(.subheadline)
                    }
                }
            }
        }
        
        if !events.isEmpty {
            Section(header: Text("Local DB: Events")) {
                ForEach(events) { event in
                    VStack(alignment: .leading) {
                        Text(event.name ?? "Unknown").font(.headline)
                        Text("Status: \(event.isClosed ? "Closed" : "Open")").font(.subheadline)
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
