
```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Función auxiliar: verifica si es admin
    function isAdmin() {
      return get(/databases/$(database)/documents/users/$(request.auth.uid))
        .data.role == 'admin';
    }
    
    // Función auxiliar: verifica si es gerente del punto
    function isManagerOfPoint(pointId) {
      return get(/databases/$(database)/documents/users/$(request.auth.uid))
        .data.thermalPointId == pointId;
    }
    
    // Función auxiliar: verifica si es el usuario actual
    function isCurrentUser(userId) {
      return request.auth.uid == userId;
    }
    
    // ==========================================
    // COLECCIÓN: users
    // ==========================================
    match /users/{userId} {
      // Leer: El usuario mismo o admin
      allow read: if isCurrentUser(userId) || isAdmin();
      
      // Escribir: Solo el usuario mismo (excepto role) o admin
      allow write: if (
        isCurrentUser(userId) && 
        !request.resource.data.role.changed()
      ) || isAdmin();
      
      // Crear: Usuario nuevo autenticado o admin
      allow create: if request.auth.uid == userId || isAdmin();
      
      // Eliminar: Solo admins
      allow delete: if isAdmin();
      
      // Sub-colecciones: check-ins del usuario
      match /checkIns/{checkInId} {
        // Leer: El usuario mismo o admin
        allow read: if isCurrentUser(userId) || isAdmin();
        
        // Crear: App backend solo
        allow create: if request.auth.token.claims.provider == 'custom';
        
        // Escribir/Eliminar: Solo admins
        allow write, delete: if isAdmin();
      }
    }
    
    // ==========================================
    // COLECCIÓN: thermalPoints
    // ==========================================
    match /thermalPoints/{pointId} {
      // Leer: Todos pueden ver
      allow read: if true;
      
      // Crear: Solo admins
      allow create: if isAdmin();
      
      // Actualizar: Admin o gerente del punto
      allow update: if isAdmin() || isManagerOfPoint(pointId);
      
      // Eliminar: Solo admins
      allow delete: if isAdmin();
      
      // Sub-colecciones: códigos QR activos
      match /activeQR/{qrId} {
        // Leer: Todos pueden ver (para validar)
        allow read: if true;
        
        // Crear: Solo admin
        allow create: if isAdmin();
        
        // Actualizar: Solo admin (para expirar QRs anteriores)
        allow update: if isAdmin();
        
        // Eliminar: Solo admin
        allow delete: if isAdmin();
      }
      
      // Sub-colecciones: imágenes
      match /images/{imageId} {
        // Leer: Todos pueden ver
        allow read: if true;
        
        // Crear: Gerente del punto o admin
        allow create: if isManagerOfPoint(pointId) || isAdmin();
        
        // Eliminar: Gerente del punto o admin
        allow delete: if isManagerOfPoint(pointId) || isAdmin();
      }
    }
    
    // ==========================================
    // COLECCIÓN: rewards
    // ==========================================
    match /rewards/{rewardId} {
      // Leer: Todos pueden ver
      allow read: if true;
      
      // Crear/Actualizar/Eliminar: Solo admins
      allow create, update, delete: if isAdmin();
    }
    
    // ==========================================
    // COLECCIÓN: routes
    // ==========================================
    match /routes/{routeId} {
      // Leer: Todos pueden ver
      allow read: if true;
      
      // Crear/Actualizar/Eliminar: Solo admins
      allow create, update, delete: if isAdmin();
    }
    
    // ==========================================
    // COLECCIÓN: achievements
    // ==========================================
    match /achievements/{achievementId} {
      // Leer: Todos pueden ver
      allow read: if true;
      
      // Escribir: Solo sistema backend
      allow write: if request.auth.token.claims.provider == 'custom';
    }
    
    // ==========================================
    // COLECCIÓN: userProgress
    // ==========================================
    match /userProgress/{userId} {
      // Leer: El usuario mismo o admin
      allow read: if isCurrentUser(userId) || isAdmin();
      
      // Escribir: El usuario mismo o sistema backend
      allow write: if (
        isCurrentUser(userId) || 
        request.auth.token.claims.provider == 'custom'
      ) || isAdmin();
    }
    
    // ==========================================
    // DENEGAR TODO LO DEMÁS
    // ==========================================
    match /{document=**} {
      allow read, write: if false;
    }
  }
  
  // ==========================================
  // REGLAS DE STORAGE
  // ==========================================
  match /b/{bucket}/o {
    match /thermalPoints/{pointId}/images/{allPaths=**} {
      // Leer: Todos pueden ver
      allow read: if true;
      
      // Escribir: Gerente del punto o admin
      allow write: if (
        isManagerOfPoint(pointId) || isAdmin()
      ) && 
      // Validar tamaño: máx 5MB
      request.resource.size < 5 * 1024 * 1024 &&
      // Validar tipo de archivo
      request.resource.contentType.matches('image/.*');
    }
    
    match /users/{userId}/profile-picture {
      // Leer: Todos pueden ver
      allow read: if true;
      
      // Escribir: El usuario mismo
      allow write: if request.auth.uid == userId &&
        request.resource.size < 2 * 1024 * 1024 &&
        request.resource.contentType.matches('image/.*');
    }
  }
}
`