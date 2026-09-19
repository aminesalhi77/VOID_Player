#pragma once

#include <QObject>
#include <QVariantList>
#include <QAudioBuffer>
#include <vector>
#include <complex>
#include <deque>

/**
 * @class AudioAnalyzer
 * @brief Real-time FFT analyzer with full dynamic range per band
 *
 * ALGORITHM:
 * 1. FFT: 2048-point Cooley-Tukey on mono audio
 * 2. Magnitude: Convert to linear spectrum
 * 3. Band Mapping: 64 logarithmic frequency bands (Mel-inspired)
 * 4. Normalization: ROLLING RMS HISTORY per band
 *    - Each band tracks last N frames' RMS
 *    - Current value normalized against (min, median, max) of history
 *    - Ensures bass-heavy songs don't pin low bands
 *    - Ensures quiet songs still show movement
 * 5. Display: Fast attack, smooth decay + peak hold
 * 6. Output: 0..1 range per band guaranteed by design
 */
class AudioAnalyzer : public QObject {
    Q_OBJECT
    Q_PROPERTY(QVariantList amplitudes READ amplitudes NOTIFY amplitudesChanged)
    Q_PROPERTY(qreal peakEnergy READ peakEnergy NOTIFY peakEnergyChanged)

public:
    explicit AudioAnalyzer(QObject* parent = nullptr);

    QVariantList amplitudes() const { return m_amplitudes; }
    qreal peakEnergy() const { return m_peakEnergy; }

public slots:
    void processBuffer(const QAudioBuffer& buffer);

signals:
    void amplitudesChanged();
    void peakEnergyChanged();

private:
    void performFFT(const std::vector<float>& input);
    static std::vector<float> hannWindow(size_t size);

    // ============ FFT Configuration ============
    static constexpr size_t FFT_SIZE  = 2048;
    static constexpr size_t NUM_BANDS = 64;
    static constexpr size_t HISTORY_SIZE = 30;  // 30 frames = ~0.5s @ 60fps

    // ============ FFT & Magnitude ============
    std::vector<float> m_fftBins;  // Raw FFT magnitude spectrum [0..FFT_SIZE/2]
    std::vector<std::complex<float>> m_fftBuffer;
    std::vector<float> m_window;

    // ============ Per-Band History & Normalization ============
    // Each band maintains a rolling history of RMS values
    // Used to compute dynamic normalization so every band reaches 0..1
    std::vector<std::deque<float>> m_bandHistory;

    // ============ Display State ============
    std::vector<float> m_display;    // Smoothed 0..1 display values (what QML reads)
    std::vector<float> m_peakHold;   // Peak hold per band (visual punch)

    // ============ Global Metrics ============
    qreal m_peakEnergy = 0.0;  // Highest display value this frame (0..1)
    qreal m_globalRMS = 0.0;   // Overall loudness reference

    QVariantList m_amplitudes;
};