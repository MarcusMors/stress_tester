pattern1="foo"
pattern2="bar"

input="bar"

case "$input" in
    $pattern1)
        echo "Matched pattern1"
        ;;
    $pattern2)
        echo "Matched pattern2"
        ;;
    *)
        echo "No match"
        ;;
esac