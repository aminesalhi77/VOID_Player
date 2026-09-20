#include "player/AudioAnalyzer.h"
#include <algorithm>
#include <cmath>
#include <numeric>

#include <QElapsedTimer>

AudioAnalyzer::AudioAnalyzer(QObject* parent)
    : QObject(parent)
{
    m_fftBins.resize(FFT_SIZE / 2, 0.0f);
    m_display.resize(NUM_BANDS, 0.0f);
    m_peakHold.resize(NUM_BANDS, 0.0f);
    m_fftBuffer.resize(FFT_SIZE);
    m_window = hannWindow(FFT_SIZE);

    // Initialize rolling history for each band
    m_bandHistory.resize(NUM_BANDS);
    for (auto& history : m_bandHistory) {
        history.resize(HISTORY_SIZE, 0.0f);  // Pre-fill with zeros
    }

    // Initialize QML property
    for (size_t i = 0; i < NUM_BANDS; i++) {
        m_amplitudes.append(0.0);
    }
}

void AudioAnalyzer::processBuffer(const QAudioBuffer& buffer) {
    // Throttle: skip frames arriving faster than ~30fps
    // (QAudioBufferOutput fires at ~43Hz; we only need 30 for smooth visuals)
    static QElapsedTimer s_throttle;
    if (!s_throttle.isValid()) s_throttle.start();
    if (s_throttle.elapsed() < 30) return;
    s_throttle.restart();

    if (!buffer.isValid()) return;

    const auto fmt = buffer.format();
    const int channels = fmt.channelCount();
    const int frames   = buffer.frameCount();
    if (frames < 128 || channels < 1) return;

    // ========== DECODE AUDIO TO MONO SAMPLES ==========
    std::vector<float> samples;
    samples.reserve(frames);

    const auto sampleFmt = fmt.sampleFormat();

    if (sampleFmt == QAudioFormat::Float) {
        const float* data = buffer.constData<float>();
        if (false) {
            for (int i = 0; i < frames; i++) {
                float s = 0;
                for (int c = 0; c < channels; c++) s += data[c * frames + i];
                samples.push_back(s / channels);
            }
        } else {
            for (int i = 0; i < frames; i++) {
                float s = 0;
                for (int c = 0; c < channels; c++) s += data[i * channels + c];
                samples.push_back(s / channels);
            }
        }
    } else if (sampleFmt == QAudioFormat::Int16) {
        const qint16* data = buffer.constData<qint16>();
        if (false) {
            for (int i = 0; i < frames; i++) {
                int32_t s = 0;
                for (int c = 0; c < channels; c++) s += data[c * frames + i];
                samples.push_back(s / (channels * 32768.0f));
            }
        } else {
            for (int i = 0; i < frames; i++) {
                int32_t s = 0;
                for (int c = 0; c < channels; c++) s += data[i * channels + c];
                samples.push_back(s / (channels * 32768.0f));
            }
        }
    } else if (sampleFmt == QAudioFormat::Int32) {
        const qint32* data = buffer.constData<qint32>();
        if (false) {
            for (int i = 0; i < frames; i++) {
                int64_t s = 0;
                for (int c = 0; c < channels; c++) s += data[c * frames + i];
                samples.push_back(s / (channels * 2147483648.0f));
            }
        } else {
            for (int i = 0; i < frames; i++) {
                int64_t s = 0;
                for (int c = 0; c < channels; c++) s += data[i * channels + c];
                samples.push_back(s / (channels * 2147483648.0f));
            }
        }
    } else {
        return;
    }

    if (samples.size() < 256) return;

    // ========== PREPARE FFT INPUT ==========
    std::vector<float> input(FFT_SIZE, 0.0f);
    const int copyCount = std::min(static_cast<int>(FFT_SIZE),
                                   static_cast<int>(samples.size()));
    const int startIdx = static_cast<int>(samples.size()) - copyCount;

    for (int i = 0; i < copyCount; i++) {
        input[FFT_SIZE - copyCount + i] = samples[startIdx + i];
    }

    for (size_t i = 0; i < FFT_SIZE; i++) {
        input[i] *= m_window[i];
    }

    // ========== PERFORM FFT ==========
    performFFT(input);

    // ========== MAP FFT TO 64 FREQUENCY BANDS ==========
    // Hybrid: LINEAR for first 32 bands, LOG for last 32
    const int binCount = static_cast<int>(m_fftBins.size());  // = 1024
    const int halfBands = NUM_BANDS / 2;                       // = 32

    for (size_t band = 0; band < NUM_BANDS; band++) {
        int startBin, endBin;

        if (static_cast<int>(band) < halfBands) {
            // LINEAR: 30 Hz → 2000 Hz for bands 0-31
            const float binHz = 44100.0f / FFT_SIZE;
            const float loBin = 30.0f / binHz;
            const float hiBin = 2000.0f / binHz;
            const float t0 = band / static_cast<float>(halfBands);
            const float t1 = (band + 1) / static_cast<float>(halfBands);
            startBin = static_cast<int>(loBin + t0 * (hiBin - loBin));
            endBin   = static_cast<int>(loBin + t1 * (hiBin - loBin));
        } else {
            // LOG: 2000 Hz → 22 kHz for bands 32-63
            const float binHz = 44100.0f / FFT_SIZE;
            const float loBin = 2000.0f / binHz;
            const float hiBin = binCount - 1;
            const int b = static_cast<int>(band) - halfBands;
            const float t0 = b / static_cast<float>(halfBands);
            const float t1 = (b + 1) / static_cast<float>(halfBands);
            startBin = static_cast<int>(loBin * std::pow(hiBin / loBin, t0));
            endBin   = static_cast<int>(loBin * std::pow(hiBin / loBin, t1));
        }

        // Ensure each band covers at least 3 bins
        if (startBin < 1) startBin = 1;
        if (endBin - startBin < 3) endBin = startBin + 3;
        if (endBin > binCount) endBin = binCount;
        if (startBin >= endBin) startBin = endBin - 1;

        // Average magnitude across bins in this band
        float energy = 0.0f;
        int count = 0;
        for (int bin = startBin; bin < endBin; bin++) {
            energy += m_fftBins[bin];
            count++;
        }
        if (count > 0) energy /= count;

        // ========== ROLLING HISTORY NORMALIZATION ==========
        m_bandHistory[band].pop_front();
        m_bandHistory[band].push_back(energy);

        float histMin = *std::min_element(m_bandHistory[band].begin(),
                                           m_bandHistory[band].end());
        float histMax = *std::max_element(m_bandHistory[band].begin(),
                                           m_bandHistory[band].end());
        float histRange = histMax - histMin;
        if (histRange < 1e-6f) histRange = 1e-6f;

        float normalized = (energy - histMin) / histRange;
        normalized = std::clamp(normalized, 0.0f, 1.0f);

        // ========== ATTACK/DECAY ENVELOPE ==========
        const float attack  = 0.8f;
        const float release = 0.12f;

        if (normalized > m_display[band]) {
            m_display[band] = attack * normalized + (1.0f - attack) * m_display[band];
        } else {
            m_display[band] = release * normalized + (1.0f - release) * m_display[band];
        }

        // ========== PEAK HOLD ==========
        if (m_display[band] > m_peakHold[band]) {
            m_peakHold[band] = m_display[band];
        } else {
            m_peakHold[band] *= 0.90f;
        }

        m_display[band] = std::max(m_display[band], m_peakHold[band] * 0.7f);
    }

    // ========== UPDATE GLOBAL PEAK ENERGY ==========
    m_peakEnergy = *std::max_element(m_display.begin(), m_display.end());

    // ========== EMIT CHANGES TO QML ==========
    QVariantList fresh;
    fresh.reserve(NUM_BANDS);
    for (float v : m_display) {
        fresh.append(static_cast<double>(v));
    }
    m_amplitudes = fresh;

    emit amplitudesChanged();
    emit peakEnergyChanged();
}

void AudioAnalyzer::performFFT(const std::vector<float>& input) {
    // ========== COPY INPUT TO COMPLEX BUFFER ==========
    for (size_t i = 0; i < FFT_SIZE; i++) {
        m_fftBuffer[i] = std::complex<float>(input[i], 0.0f);
    }

    // ========== COOLEY-TUKEY RADIX-2 FFT ==========
    // Classic in-place FFT implementation
    // Time complexity: O(N log N)

    const size_t N = FFT_SIZE;

    // Butterfly operations by stage
    for (size_t s = 1; s <= static_cast<size_t>(std::log2(N)); s++) {
        const size_t m = 1 << s;  // Current butterfly span
        const std::complex<float> wm = std::exp(std::complex<float>(0, -2.0f * M_PI / m));

        for (size_t k = 0; k < N; k += m) {
            std::complex<float> w(1.0f);
            for (size_t j = 0; j < m / 2; j++) {
                const auto u = m_fftBuffer[k + j];
                const auto v = m_fftBuffer[k + j + m / 2] * w;
                m_fftBuffer[k + j] = u + v;
                m_fftBuffer[k + j + m / 2] = u - v;
                w *= wm;
            }
        }
    }

    // ========== BIT-REVERSAL PERMUTATION ==========
    size_t j = 0;
    for (size_t i = 0; i < N - 1; i++) {
        if (i < j) std::swap(m_fftBuffer[i], m_fftBuffer[j]);
        size_t mask = N;
        while (j & (mask >>= 1)) j &= ~mask;
        j |= mask;
    }

    // ========== EXTRACT MAGNITUDE SPECTRUM ==========
    for (size_t i = 0; i < m_fftBins.size(); i++) {
        const float real = m_fftBuffer[i].real();
        const float imag = m_fftBuffer[i].imag();
        const float mag = std::sqrt(real * real + imag * imag) / FFT_SIZE;
        m_fftBins[i] = mag;
    }
}

std::vector<float> AudioAnalyzer::hannWindow(size_t size) {
    std::vector<float> window(size);
    for (size_t i = 0; i < size; i++) {
        window[i] = 0.5f * (1.0f - std::cos(2.0f * M_PI * i / (size - 1)));
    }
    return window;
}