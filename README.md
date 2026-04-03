# SplitApp

## Использование сети и базы данных на экранах (Views)

### Сеть (APIClient)
Для всех сетевых запросов используйте синглтон `APIClient.shared`. Он использует современный синтаксис `async/await`. Специфичные методы определены в `extension` для различных сущностей (пользователи, события, чеки).

Пример:
```swift
func fetchEvents() async {
    do {
        // 1. Получение данных из API
        let events = try await APIClient.shared.listEvents()
        
        // 2. Сохранение в Core Data в фоновом потоке
        try await CoreDataStore.shared.performBackground { context in
            try CoreDataStore.shared.upsertEvents(events, in: context)
            // Нет необходимости вручную сохранять контекст, performBackground сделает это при наличии изменений.
        }
    } catch {
        print("Ошибка сети: \(error)")
    }
}
```

### База данных (CoreDataStore)
Для локального сохранения данных используйте `CoreDataStore.shared`. 

- **Чтение данных в SwiftUI:** Используйте обертку `@FetchRequest` внутри ваших view. Либо, если вам нужно получить данные программно, используйте методы вроде `fetchAllEvents(in:)`, передавая в них `CoreDataStore.shared.viewContext`.
- **Изменение данных:** Обязательно используйте метод `performBackground` для любых операций добавления, обновления или удаления, чтобы не блокировать главный поток (UI thread). Контекст будет сохранен автоматически.

Пример (Сохранение данных):
```swift
func saveLocally(dto: EventDTO) async {
    do {
        try await CoreDataStore.shared.performBackground { context in
            try CoreDataStore.shared.upsertEvent(dto, in: context)
        }
    } catch {
        print("Ошибка БД: \(error)")
    }
}
```

Пример (Получение данных в SwiftUI):
```swift
import SwiftUI

struct EventsView: View {
    @FetchRequest(
        entity: CDEvent.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CDEvent.createdAt, ascending: false)]
    ) var events: FetchedResults<CDEvent>

    var body: some View {
        List(events) { event in
            Text(event.name ?? "Безымянное событие")
        }
    }
}
```