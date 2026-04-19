using System.Globalization;
using System.Windows.Data;

namespace PopPrompt.Windows.Helpers;

public sealed class CopyGlyphConverter : IValueConverter
{
    public object Convert(object value, Type targetType, object parameter, CultureInfo culture)
    {
        return value is true ? "✓" : "⧉";
    }

    public object ConvertBack(object value, Type targetType, object parameter, CultureInfo culture)
    {
        throw new NotSupportedException();
    }
}
