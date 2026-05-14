package main

import (
	"fmt"
	"image"

	_ "image/jpeg"
	_ "image/png"
	"log"
	"math"
	"os"
	"os/exec"
	"regexp"
	"sort"
)

// Fallback Mocha/Waybar colors
const (
	fallbackRosewater = "f5e0dc"
	fallbackPink      = "f5c2e7"
	fallbackRed       = "f38ba8"
	fallbackPeach     = "fab387"
	fallbackYellow    = "f9e2af"
	fallbackGreen     = "a6e3a1"
	fallbackBlue      = "89b4fa"
	fallbackLavender  = "b4befe"
	fallbackText      = "cdd6f4"
	fallbackBase      = "1e1e2e"
	fallbackMantle    = "181825"
	fallbackCrust     = "11111b"

	waybarBaseBg      = "rgba(30, 33, 94, 0.65)"
	waybarSurfacePill = "rgb(100, 165, 249)"
	waybarPrimaryBlue = "#0e124c"
	waybarMiddleBg    = "#232176"
	waybarBlack       = "#000000"
	waybarSuccess     = "#9ece6a"
)

type Bucket struct {
	Count int
	R, G, B uint32
}

func main() {
	if len(os.Args) < 2 {
		log.Fatalf("Usage: %s <path-to-wallpaper>", os.Args[0])
	}
	wallpaper := os.Args[1]

	domBase, domAccent, err := extractColors(wallpaper)
	if err != nil {
		log.Printf("Failed to extract colors: %v. Using fallbacks.", err)
		domBase = fallbackBase
		domAccent = fallbackBlue
	} else {
		log.Printf("Extracted dominant background: #%s, accent: #%s", domBase, domAccent)
	}

	// Generate conf and css
	err = generateFiles(domBase, domAccent)
	if err != nil {
		log.Fatalf("Failed to generate files: %v", err)
	}
    
    // Also update dunstrc
    updateDunst(domBase, domAccent)

	fmt.Println("Color theme updated!")
    // Trigger reloading
    exec.Command("hyprctl", "reload").Run()
    exec.Command("pkill", "waybar").Run()
    exec.Command("bash", "-c", "waybar &").Start()
    exec.Command("killall", "dunst").Run()
    exec.Command("bash", "-c", "dunst &").Start()
}

func extractColors(path string) (string, string, error) {
	file, err := os.Open(path)
	if err != nil {
		return "", "", err
	}
	defer file.Close()

	img, _, err := image.Decode(file)
	if err != nil {
		return "", "", err
	}

	bounds := img.Bounds()
	stepX := int(math.Max(1, float64(bounds.Dx())/100))
	stepY := int(math.Max(1, float64(bounds.Dy())/100))

	buckets := make(map[uint32]*Bucket)

	for y := bounds.Min.Y; y < bounds.Max.Y; y += stepY {
		for x := bounds.Min.X; x < bounds.Max.X; x += stepX {
			c := img.At(x, y)
			r, g, b, _ := c.RGBA()
			r8, g8, b8 := r>>8, g>>8, b>>8

			// Quantize by dividing by 32 to group similar colors
			bucketSize := uint32(32)
			rBuck, gBuck, bBuck := r8/bucketSize, g8/bucketSize, b8/bucketSize
			bucketID := (rBuck << 16) | (gBuck << 8) | bBuck

			if _, ok := buckets[bucketID]; !ok {
				buckets[bucketID] = &Bucket{}
			}
			buckets[bucketID].Count++
			buckets[bucketID].R += r8
			buckets[bucketID].G += g8
			buckets[bucketID].B += b8
		}
	}

	var sorted []*Bucket
	for _, b := range buckets {
		sorted = append(sorted, b)
	}
	sort.Slice(sorted, func(i, j int) bool {
		return sorted[i].Count > sorted[j].Count
	})

	if len(sorted) == 0 {
		return fallbackBase, fallbackBlue, fmt.Errorf("no colors extracted")
	}

	// Calculate average color for the most dominant bucket
	bgBucket := sorted[0]
	bgHex := fmt.Sprintf("%02x%02x%02x", bgBucket.R/uint32(bgBucket.Count), bgBucket.G/uint32(bgBucket.Count), bgBucket.B/uint32(bgBucket.Count))

	// Find the first bucket that has a distinct color from background (accent color)
	accentHex := fallbackBlue
	for i := 1; i < len(sorted); i++ {
		// Calculate color distance (euclidean)
		bR, bG, bB := bgBucket.R/uint32(bgBucket.Count), bgBucket.G/uint32(bgBucket.Count), bgBucket.B/uint32(bgBucket.Count)
		aR, aG, aB := sorted[i].R/uint32(sorted[i].Count), sorted[i].G/uint32(sorted[i].Count), sorted[i].B/uint32(sorted[i].Count)
		
        dist := math.Sqrt(float64((bR-aR)*(bR-aR) + (bG-aG)*(bG-aG) + (bB-aB)*(bB-aB)))
		if dist > 80 { // Threshold for "distinct"
			accentHex = fmt.Sprintf("%02x%02x%02x", aR, aG, aB)
			break
		}
	}

	return bgHex, accentHex, nil
}

func generateFiles(bgHex string, accentHex string) error {
	// Parse hex to decimal for RGB values
	var bgR, bgG, bgB int
	fmt.Sscanf(bgHex, "%02x%02x%02x", &bgR, &bgG, &bgB)
    var accentR, accentG, accentB int
    fmt.Sscanf(accentHex, "%02x%02x%02x", &accentR, &accentG, &accentB)

    // Calculate luminance to decide text color (contrast)
    luminance := (0.299 * float64(bgR)) + (0.587 * float64(bgG)) + (0.114 * float64(bgB))
    textColor := fallbackText
    if luminance > 128 {
        textColor = fallbackCrust // Dark text for bright backgrounds
    }

	cssContent := fmt.Sprintf(`/* Extracted Theme CSS */
@define-color base #%s;
@define-color primary-blue #%s;
@define-color middle-bg #%s; 
@define-color surface-pill #%s;
@define-color base-bg rgba(%d, %d, %d, 0.65);
@define-color border-glass rgba(255, 255, 255, 0.08);

/* Fallbacks from Mocha */
@define-color rosewater #%s;
@define-color pink #%s;
@define-color red #%s;
@define-color peach #%s;
@define-color yellow #%s;
@define-color green #%s;
@define-color blue #%s;
@define-color lavender #%s;
@define-color text #%s;
@define-color crust #%s;

/* Waybar specifics */
@define-color text-main #%s;
@define-color black %s;
@define-color success %s;
`, bgHex, accentHex, bgHex, accentHex, bgR, bgG, bgB, fallbackRosewater, fallbackPink, fallbackRed, fallbackPeach, fallbackYellow, fallbackGreen, accentHex, fallbackLavender, fallbackText, fallbackCrust, textColor, waybarBlack, waybarSuccess)

	confContent := fmt.Sprintf(`# Extracted Theme Conf
$base = rgb(%s)
$blue = rgb(%s)
$rosewater = rgb(%s)
$pink = rgb(%s)
$red = rgb(%s)
$peach = rgb(%s)
$yellow = rgb(%s)
$green = rgb(%s)
$lavender = rgb(%s)
$text = rgb(%s)
$crust = rgb(%s)

$base_bg = rgba(%02x%02x%02xa6)
$surface_pill = rgb(%s)
$primary_blue = rgb(%s)
$middle_bg = rgb(%s)
`, bgHex, accentHex, fallbackRosewater, fallbackPink, fallbackRed, fallbackPeach, fallbackYellow, fallbackGreen, fallbackLavender, textColor, fallbackCrust, bgR, bgG, bgB, accentHex, accentHex, bgHex)

	rasiContent := fmt.Sprintf(`* {
    base: #%s;
    primary-blue: #%s;
    middle-bg: #%s;
    surface-pill: #%s;
    text-main: #%s;
    text-muted: #%s80;
    transparent: #00000000;
}
`, bgHex, accentHex, bgHex, accentHex, textColor, textColor)

    home, _ := os.UserHomeDir()
    themePath := home + "/dotfiles/theme/.config/theme"
	cssPath := themePath + "/colors.css"
	confPath := themePath + "/colors.conf"
	rasiPath := themePath + "/colors.rasi"

	if err := os.WriteFile(cssPath, []byte(cssContent), 0644); err != nil {
		return err
	}
	if err := os.WriteFile(confPath, []byte(confContent), 0644); err != nil {
		return err
	}
	if err := os.WriteFile(rasiPath, []byte(rasiContent), 0644); err != nil {
		return err
	}
	return nil
}

func updateDunst(bgHex, accentHex string) {
	home, _ := os.UserHomeDir()
	path := home + "/dotfiles/dunst/.config/dunst/dunstrc"
	content, err := os.ReadFile(path)
	if err != nil {
		return
	}

    var bgR, bgG, bgB int
	fmt.Sscanf(bgHex, "%02x%02x%02x", &bgR, &bgG, &bgB)
    luminance := (0.299 * float64(bgR)) + (0.587 * float64(bgG)) + (0.114 * float64(bgB))
    fgHex := fallbackText
    if luminance > 128 {
        fgHex = fallbackCrust // Dark text
    }

	// Replace normal and low urgency backgrounds, but preserve critical
	reLowBg := regexp.MustCompile(`(?s)(\[urgency_low\].*?background =) ".[a-fA-F0-9]+"`)
	content = reLowBg.ReplaceAll(content, []byte(fmt.Sprintf(`${1} "#%s"`, bgHex)))
    
	reNormBg := regexp.MustCompile(`(?s)(\[urgency_normal\].*?background =) ".[a-fA-F0-9]+"`)
	content = reNormBg.ReplaceAll(content, []byte(fmt.Sprintf(`${1} "#%s"`, bgHex)))

	reLowFg := regexp.MustCompile(`(?s)(\[urgency_low\].*?foreground =) ".[a-fA-F0-9]+"`)
	content = reLowFg.ReplaceAll(content, []byte(fmt.Sprintf(`${1} "#%s"`, fgHex)))
    
	reNormFg := regexp.MustCompile(`(?s)(\[urgency_normal\].*?foreground =) ".[a-fA-F0-9]+"`)
	content = reNormFg.ReplaceAll(content, []byte(fmt.Sprintf(`${1} "#%s"`, fgHex)))

    reLowFrame := regexp.MustCompile(`(?s)(\[urgency_low\].*?frame_color =) ".[a-fA-F0-9]+"`)
	content = reLowFrame.ReplaceAll(content, []byte(fmt.Sprintf(`${1} "#%s"`, accentHex)))
    
	reNormFrame := regexp.MustCompile(`(?s)(\[urgency_normal\].*?frame_color =) ".[a-fA-F0-9]+"`)
	content = reNormFrame.ReplaceAll(content, []byte(fmt.Sprintf(`${1} "#%s"`, accentHex)))

	os.WriteFile(path, content, 0644)
}
