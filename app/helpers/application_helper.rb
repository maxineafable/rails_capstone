module ApplicationHelper
  TAGALOG_MONTHS = %w[Enero Pebrero Marso Abril Mayo Hunyo Hulyo Agosto Setyembre Oktubre Nobyembre Disyembre].freeze

  def tagalog_date(date)
    "#{date.day} #{TAGALOG_MONTHS[date.month - 1]} #{date.year}"
  end

  def tagalog_datetime(date)
    "#{tagalog_date(date)} - #{date.strftime('%I:%M %p')}"
  end

  def tagalog_status(status)
    translations = {
      "pending" => "Naghihintay",
      "processing" => "Pinoproseso",
      "ready to pickup" => "Handa nang kunin",
      "ready_to_pickup" => "Handa nang kunin",
      "claimed" => "Nakuha na",
      "rejected" => "Tinanggihan",
      "submitted" => "Naipasa",
      "ongoing" => "Isinasagawa",
      "in progress" => "Isinasagawa",
      "resolved" => "Nalutas",
      "completed" => "Natapos",
      "unactionable" => "Hindi maaaksyunan",
      "approved" => "Naaprubahan",
      "cancelled" => "Kinansela",
      "canceled" => "Kinansela"
    }

    translations.fetch(status.to_s.downcase.tr("_", " "), status.to_s.humanize)
  end

  def tagalog_status_class(status)
    classes = {
      "pending" => "bg-amber-100 text-amber-900",
      "processing" => "bg-blue-100 text-blue-900",
      "ongoing" => "bg-blue-100 text-blue-900",
      "in progress" => "bg-blue-100 text-blue-900",
      "ready to pickup" => "bg-emerald-200 text-emerald-900",
      "claimed" => "bg-emerald-200 text-emerald-900",
      "resolved" => "bg-emerald-200 text-emerald-900",
      "completed" => "bg-emerald-200 text-emerald-900",
      "rejected" => "bg-rose-100 text-rose-900",
      "unactionable" => "bg-rose-100 text-rose-900"
    }

    classes.fetch(status.to_s.downcase.tr("_", " "), "bg-slate-100 text-slate-700")
  end

  def tagalog_label(value)
    translations = {
      "barangay clearance" => "Barangay Clearance",
      "certificate of indigency" => "Certificate of Indigency",
      "certificate of residency" => "Certificate of Residency",
      "good moral character" => "Certificate of Good Moral Character",
      "certificate of income" => "Certificate of Income",
      "certificate of low income" => "Certificate of Low Income",
      "health and sanitation" => "Kalusugan at Kalinisan",
      "infrastructure" => "Imprastraktura",
      "peace and order" => "Kapayapaan at Kaayusan",
      "waste management" => "Pamamahala ng Basura",
      "others" => "Iba pa",
      "national id" => "Pambansang ID",
      "drivers license" => "Lisensya sa Pagmamaneho",
      "passport" => "Pasaporte",
      "philhealth" => "PhilHealth ID",
      "single" => "Walang asawa",
      "married" => "May asawa",
      "widowed" => "Balo",
      "divorced" => "Diborsyado",
      "separated" => "Hiwalay",
      "male" => "Lalaki",
      "female" => "Babae"
    }
    label = value.to_s.humanize

    translations.fetch(label.downcase, label)
  end
end
