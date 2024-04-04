namespace FeatureLogging
{
    public struct ValidationResult(bool valid, string? error = null)
    {
        public bool Valid { get; private set; } = valid;

        public string? Error { get; private set; } = error;

        public static bool operator ==(ValidationResult x, ValidationResult y)
        {
            var xPrime = x;
            var yPrime = y;
            if (xPrime.Valid && yPrime.Valid)
            {
                return true;
            }
            if (xPrime.Valid || yPrime.Valid)
            {
                return false;
            }
            return xPrime.Error == yPrime.Error;
        }

        public static bool operator !=(ValidationResult x, ValidationResult y)
        {
            return !(x == y);
        }

        public override readonly bool Equals(object? obj)
        {
            if (obj is ValidationResult)
            {
                var objAsValidationResult = obj as ValidationResult?;
                return this == objAsValidationResult;
            }
            return false;
        }

        public override readonly int GetHashCode()
        {
            return Valid.GetHashCode() + (Error ?? "").GetHashCode();
        }
    }
}
