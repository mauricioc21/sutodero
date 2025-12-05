#!/usr/bin/env python3
"""
Script para configurar reglas de seguridad de Firestore para la colección 'actas'
Soluciona el error: [cloud_firestore/permission-denied] Missing or insufficient permissions
"""

import json
import sys

try:
    import firebase_admin
    from firebase_admin import credentials, firestore
    print("✅ firebase-admin imported successfully")
except ImportError as e:
    print(f"❌ Failed to import firebase-admin: {e}")
    print("📦 INSTALLATION REQUIRED:")
    print("pip install firebase-admin==7.1.0")
    sys.exit(1)

def main():
    print("=" * 60)
    print("🔧 CONFIGURADOR DE REGLAS DE FIRESTORE - COLECCIÓN 'ACTAS'")
    print("=" * 60)
    
    # Buscar archivo de credenciales
    import os
    import glob
    
    firebase_key_paths = [
        "/opt/flutter/firebase-admin-sdk.json",
        *glob.glob("/opt/flutter/*adminsdk*.json")
    ]
    
    firebase_key_path = None
    for path in firebase_key_paths:
        if os.path.exists(path):
            firebase_key_path = path
            break
    
    if not firebase_key_path:
        print("❌ No se encontró el archivo de credenciales de Firebase Admin SDK")
        print("📍 Ubicaciones buscadas:")
        for path in firebase_key_paths:
            print(f"   - {path}")
        sys.exit(1)
    
    print(f"✅ Credenciales encontradas: {firebase_key_path}")
    
    try:
        # Inicializar Firebase Admin
        cred = credentials.Certificate(firebase_key_path)
        
        # Verificar si ya está inicializado
        try:
            firebase_admin.get_app()
            print("✅ Firebase Admin ya inicializado")
        except ValueError:
            firebase_admin.initialize_app(cred)
            print("✅ Firebase Admin inicializado correctamente")
        
        # Obtener cliente de Firestore
        db = firestore.client()
        print("✅ Cliente de Firestore conectado")
        
        # Leer project_id del archivo de credenciales
        with open(firebase_key_path, 'r') as f:
            creds_data = json.load(f)
            project_id = creds_data.get('project_id')
        
        print(f"\n📋 Proyecto Firebase: {project_id}")
        
        # Las reglas de seguridad de Firestore se deben configurar manualmente
        # o mediante Firebase CLI, pero podemos proporcionar las reglas correctas
        
        print("\n" + "=" * 60)
        print("📝 REGLAS DE FIRESTORE RECOMENDADAS")
        print("=" * 60)
        
        recommended_rules = """
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Colección de actas - permitir lectura/escritura autenticada
    match /actas/{actaId} {
      // Permitir lectura si está autenticado
      allow read: if request.auth != null;
      
      // Permitir escritura si está autenticado
      allow create: if request.auth != null;
      allow update: if request.auth != null;
      allow delete: if request.auth != null;
    }
    
    // Para desarrollo: permitir todo (SOLO PARA TESTING)
    // ⚠️ CAMBIAR EN PRODUCCIÓN
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
"""
        
        print(recommended_rules)
        
        print("\n" + "=" * 60)
        print("🔧 INSTRUCCIONES PARA APLICAR LAS REGLAS")
        print("=" * 60)
        print("\n📍 Opción 1: Firebase Console (Recomendado)")
        print("   1. Ve a: https://console.firebase.google.com/")
        print(f"   2. Selecciona tu proyecto: {project_id}")
        print("   3. Ve a: Firestore Database → Rules")
        print("   4. Copia y pega las reglas mostradas arriba")
        print("   5. Click en 'Publicar'")
        
        print("\n📍 Opción 2: Firebase CLI")
        print("   1. Instala Firebase CLI: npm install -g firebase-tools")
        print("   2. Login: firebase login")
        print(f"   3. Selecciona proyecto: firebase use {project_id}")
        print("   4. Edita firestore.rules con las reglas de arriba")
        print("   5. Despliega: firebase deploy --only firestore:rules")
        
        print("\n" + "=" * 60)
        print("⚠️  IMPORTANTE: REGLAS DE DESARROLLO vs PRODUCCIÓN")
        print("=" * 60)
        print("\n🔧 DESARROLLO (Permitir todo - TEMPORAL):")
        print("   match /{document=**} {")
        print("     allow read, write: if true;")
        print("   }")
        
        print("\n🔒 PRODUCCIÓN (Seguro - RECOMENDADO):")
        print("   match /actas/{actaId} {")
        print("     allow read: if request.auth != null;")
        print("     allow write: if request.auth != null &&")
        print("                    request.auth.uid == resource.data.userId;")
        print("   }")
        
        # Intentar verificar si la colección 'actas' existe
        print("\n" + "=" * 60)
        print("🔍 VERIFICANDO COLECCIÓN 'ACTAS'")
        print("=" * 60)
        
        try:
            actas_ref = db.collection('actas')
            actas_sample = actas_ref.limit(1).get()
            
            if len(actas_sample) > 0:
                print(f"✅ Colección 'actas' existe ({len(actas_sample)} documento encontrado)")
            else:
                print("⚠️  Colección 'actas' existe pero está vacía")
        except Exception as e:
            print(f"⚠️  No se pudo verificar la colección: {e}")
        
        print("\n" + "=" * 60)
        print("✅ SCRIPT COMPLETADO")
        print("=" * 60)
        print("\n📌 PRÓXIMOS PASOS:")
        print("   1. Aplica las reglas de Firestore usando Firebase Console")
        print("   2. Reinicia tu aplicación Flutter")
        print("   3. Intenta guardar un acta nuevamente")
        
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)

if __name__ == '__main__':
    main()
