-- Database Schema for Kids Growing Pediatric Clinic Assistant
-- PostgreSQL Database

-- ============================================
-- PATIENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS patients (
    patient_id SERIAL PRIMARY KEY,
    patient_name VARCHAR(255) NOT NULL,
    date_of_birth DATE,
    age INTEGER,
    gender VARCHAR(20),
    parent_name VARCHAR(255) NOT NULL,
    parent_email VARCHAR(255),
    parent_phone VARCHAR(50) NOT NULL,
    address TEXT,
    insurance_provider VARCHAR(255),
    insurance_policy_number VARCHAR(100),
    allergies JSONB DEFAULT '[]',
    medical_conditions JSONB DEFAULT '[]',
    medications JSONB DEFAULT '[]',
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for faster lookups
CREATE INDEX idx_patients_parent_email ON patients(parent_email);
CREATE INDEX idx_patients_parent_phone ON patients(parent_phone);
CREATE INDEX idx_patients_patient_name ON patients(patient_name);

-- ============================================
-- APPOINTMENTS TABLE
-- ============================================
CREATE TABLE IF NOT EXISTS appointments (
    appointment_id VARCHAR(255) PRIMARY KEY, -- Google Calendar Event ID
    patient_id INTEGER REFERENCES patients(patient_id),
    patient_name VARCHAR(255) NOT NULL,
    patient_age INTEGER,
    parent_name VARCHAR(255) NOT NULL,
    parent_email VARCHAR(255),
    parent_phone VARCHAR(50) NOT NULL,
    reason_for_visit TEXT,
    appointment_date TIMESTAMP NOT NULL,
    status VARCHAR(50) DEFAULT 'scheduled', -- scheduled, completed, cancelled, no_show
    reminder_24h_sent BOOLEAN DEFAULT FALSE,
    reminder_1h_sent BOOLEAN DEFAULT FALSE,
    notes TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Indexes for appointment queries
CREATE INDEX idx_appointments_date ON appointments(appointment_date);
CREATE INDEX idx_appointments_status ON appointments(status);
CREATE INDEX idx_appointments_parent_email ON appointments(parent_email);
CREATE INDEX idx_appointments_reminders ON appointments(appointment_date, status, reminder_24h_sent, reminder_1h_sent);

-- ============================================
-- PATIENT ACTIVITY LOG (GDPR/HIPAA Compliance)
-- ============================================
CREATE TABLE IF NOT EXISTS patient_activity_log (
    log_id SERIAL PRIMARY KEY,
    activity_type VARCHAR(50) NOT NULL, -- create, update, get, search, delete
    patient_id INTEGER,
    user_id VARCHAR(255),
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(100),
    user_agent TEXT,
    notes TEXT
);

-- Index for compliance audits
CREATE INDEX idx_activity_log_patient ON patient_activity_log(patient_id);
CREATE INDEX idx_activity_log_timestamp ON patient_activity_log(timestamp);

-- ============================================
-- REMINDER LOG
-- ============================================
CREATE TABLE IF NOT EXISTS reminder_log (
    reminder_id SERIAL PRIMARY KEY,
    appointment_id VARCHAR(255) REFERENCES appointments(appointment_id),
    reminder_type VARCHAR(10) NOT NULL, -- 24h, 1h
    sent_via_sms BOOLEAN DEFAULT FALSE,
    sent_via_email BOOLEAN DEFAULT FALSE,
    sent_via_whatsapp BOOLEAN DEFAULT FALSE,
    sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    delivery_status VARCHAR(50), -- sent, delivered, failed
    error_message TEXT
);

-- Index for tracking reminder delivery
CREATE INDEX idx_reminder_log_appointment ON reminder_log(appointment_id);
CREATE INDEX idx_reminder_log_sent_at ON reminder_log(sent_at);

-- ============================================
-- CONVERSATION SESSIONS (Optional - if not using Redis)
-- ============================================
CREATE TABLE IF NOT EXISTS conversation_sessions (
    session_id VARCHAR(255) PRIMARY KEY,
    user_id VARCHAR(255),
    channel VARCHAR(50), -- web, whatsapp, sms, voice
    conversation_history JSONB DEFAULT '[]',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP
);

-- Index for session cleanup
CREATE INDEX idx_sessions_expires ON conversation_sessions(expires_at);

-- ============================================
-- FAQ CATEGORIES (Optional - for storing common questions)
-- ============================================
CREATE TABLE IF NOT EXISTS faq_categories (
    category_id SERIAL PRIMARY KEY,
    category_name VARCHAR(255) NOT NULL,
    description TEXT,
    display_order INTEGER DEFAULT 0
);

CREATE TABLE IF NOT EXISTS faqs (
    faq_id SERIAL PRIMARY KEY,
    category_id INTEGER REFERENCES faq_categories(category_id),
    question TEXT NOT NULL,
    answer TEXT NOT NULL,
    keywords TEXT[], -- For better search
    display_order INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index for FAQ search
CREATE INDEX idx_faqs_category ON faqs(category_id);
CREATE INDEX idx_faqs_keywords ON faqs USING GIN(keywords);

-- ============================================
-- CLINIC SETTINGS
-- ============================================
CREATE TABLE IF NOT EXISTS clinic_settings (
    setting_key VARCHAR(255) PRIMARY KEY,
    setting_value TEXT,
    description TEXT,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Insert default settings
INSERT INTO clinic_settings (setting_key, setting_value, description) VALUES
('clinic_name', 'Kids Growing - Clínica Pediátrica', 'Clinic name'),
('clinic_phone', '+1 (555) 123-4567', 'Main phone number'),
('clinic_email', 'contacto@kidsgrowing.com', 'Main email'),
('clinic_address', 'Av. Principal #123, Ciudad', 'Physical address'),
('working_hours_weekday', '8:00-18:00', 'Monday to Friday hours'),
('working_hours_saturday', '9:00-14:00', 'Saturday hours'),
('appointment_duration_minutes', '30', 'Default appointment duration'),
('emergency_number', '911', 'Emergency contact number')
ON CONFLICT (setting_key) DO NOTHING;

-- ============================================
-- VIEWS FOR REPORTING
-- ============================================

-- View: Upcoming appointments with patient details
CREATE OR REPLACE VIEW v_upcoming_appointments AS
SELECT
    a.appointment_id,
    a.appointment_date,
    a.patient_name,
    a.patient_age,
    a.parent_name,
    a.parent_phone,
    a.parent_email,
    a.reason_for_visit,
    a.status,
    a.reminder_24h_sent,
    a.reminder_1h_sent,
    p.allergies,
    p.medical_conditions
FROM appointments a
LEFT JOIN patients p ON a.patient_id = p.patient_id
WHERE a.status = 'scheduled'
  AND a.appointment_date >= CURRENT_TIMESTAMP
ORDER BY a.appointment_date ASC;

-- View: Patient visit history
CREATE OR REPLACE VIEW v_patient_history AS
SELECT
    p.patient_id,
    p.patient_name,
    p.parent_name,
    p.parent_email,
    p.parent_phone,
    COUNT(a.appointment_id) as total_appointments,
    COUNT(CASE WHEN a.status = 'completed' THEN 1 END) as completed_appointments,
    COUNT(CASE WHEN a.status = 'cancelled' THEN 1 END) as cancelled_appointments,
    MAX(a.appointment_date) as last_visit_date,
    MIN(a.appointment_date) as first_visit_date
FROM patients p
LEFT JOIN appointments a ON p.patient_id = a.patient_id
GROUP BY p.patient_id, p.patient_name, p.parent_name, p.parent_email, p.parent_phone;

-- ============================================
-- FUNCTIONS
-- ============================================

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Triggers for auto-updating timestamps
CREATE TRIGGER update_patients_updated_at BEFORE UPDATE ON patients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_appointments_updated_at BEFORE UPDATE ON appointments
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_faqs_updated_at BEFORE UPDATE ON faqs
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- SAMPLE DATA (Optional - for testing)
-- ============================================

-- Sample FAQ Categories
INSERT INTO faq_categories (category_name, description, display_order) VALUES
('Información General', 'Preguntas sobre la clínica', 1),
('Citas', 'Preguntas sobre agendamiento', 2),
('Servicios', 'Servicios que ofrecemos', 3),
('Seguros', 'Información sobre seguros médicos', 4),
('Vacunación', 'Información sobre vacunas', 5)
ON CONFLICT DO NOTHING;

-- Sample FAQs
INSERT INTO faqs (category_id, question, answer, keywords) VALUES
(1, '¿Cuál es el horario de atención?',
 'Nuestro horario es: Lunes a Viernes de 8:00 AM a 6:00 PM, Sábados de 9:00 AM a 2:00 PM. Cerrado los domingos.',
 ARRAY['horario', 'horas', 'abierto', 'cerrado']),
(1, '¿Dónde están ubicados?',
 'Estamos ubicados en Av. Principal #123, Ciudad. Contamos con estacionamiento gratuito.',
 ARRAY['ubicación', 'dirección', 'donde', 'estacionamiento']),
(2, '¿Cómo puedo agendar una cita?',
 'Puedes agendar una cita a través de este chat, llamando al +1 (555) 123-4567, o enviando un email a contacto@kidsgrowing.com',
 ARRAY['agendar', 'cita', 'reservar', 'appointment']),
(3, '¿Qué servicios ofrecen?',
 'Ofrecemos consulta pediátrica general, control de niño sano, vacunación, urgencias pediátricas, y consultas especializadas.',
 ARRAY['servicios', 'ofrecen', 'que hacen']),
(4, '¿Aceptan seguros médicos?',
 'Sí, aceptamos la mayoría de seguros médicos. Por favor proporciona tu información de seguro al agendar la cita.',
 ARRAY['seguro', 'insurance', 'cobertura'])
ON CONFLICT DO NOTHING;
