import org.apache.flink.api.common.functions.FlatMapFunction;
import org.apache.flink.api.common.functions.MapFunction;
import org.apache.flink.api.common.functions.ReduceFunction;
import org.apache.flink.api.common.functions.RichMapFunction;
import org.apache.flink.api.java.DataSet;
import org.apache.flink.api.java.ExecutionEnvironment;
import org.apache.flink.api.java.functions.FunctionAnnotation.ForwardedFields;
import org.apache.flink.api.java.operators.DataSource;
import org.apache.flink.api.java.operators.IterativeDataSet;
import org.apache.flink.api.java.tuple.Tuple14;
import org.apache.flink.api.java.tuple.Tuple2;
import org.apache.flink.api.java.tuple.Tuple3;
import org.apache.flink.api.java.utils.ParameterTool;
import org.apache.flink.configuration.Configuration;
import org.apache.flink.util.Collector;


import javax.xml.crypto.Data;
import java.io.Serializable;
import java.util.Collection;

/**
 * based on the example from the flink github repository and mentioned in the task
 */
@SuppressWarnings("serial")
public class CellCluster {

    public static void main(String[] args) throws Exception {

        // Checking input parameters
        final ParameterTool params = ParameterTool.fromArgs(args);

        // set up execution environment
        ExecutionEnvironment env = ExecutionEnvironment.getExecutionEnvironment();
        env.getConfig().setGlobalJobParameters(params); // make parameters available in the web interface

        // read the input data:
        DataSource<Tuple14<String, Integer, Integer, Integer, Integer, Integer, Double, Double, Integer, Integer, Integer, Integer, Integer, Integer>> data =
                env.readCsvFile(params.get("input"))
                        .fieldDelimiter(',')
                        .ignoreFirstLine()
                        .types(String.class, Integer.class, Integer.class, Integer.class, Integer.class, Integer.class, Double.class, Double.class, Integer.class, Integer.class, Integer.class, Integer.class, Integer.class, Integer.class);

        // process input data
        DataSet<Point> points = processPoints(data, params);
        DataSet<Centroid> centroids = processCentroids(data, params);

        // in case k is provided
        if (params.has("k")) {
            System.out.println("Detected k value, which is: " + params.get("k") + "\ncentroids: " + centroids.count());
            if ((int) (long) centroids.count() > Integer.parseInt(params.get("k"))) {
                centroids = centroids.first(Integer.parseInt(params.get("k")));
            }
        }

        // set number of bulk iterations for KMeans algorithm
        IterativeDataSet<Centroid> loop = centroids.iterate(params.getInt("iterations", 10));

        DataSet<Centroid> newCentroids = points
                // compute closest centroid for each point
                .map(new SelectNearestCenter()).withBroadcastSet(loop, "centroids")
                // count and sum point coordinates for each centroid
                .map(new CountAppender())
                .groupBy(0).reduce(new CentroidAccumulator())
                // compute new centroids from point counts and coordinate sums
                .map(new CentroidAverager());

        // feed new centroids back into next iteration
        DataSet<Centroid> finalCentroids = loop.closeWith(newCentroids);

        DataSet<Tuple2<Integer, Point>> clusteredPoints = points
                // assign points to final clusters
                .map(new SelectNearestCenter()).withBroadcastSet(finalCentroids, "centroids");

        DataSet<Tuple3<Integer, Double, Double>> csvPoints = clusteredPoints.map(new MapFunction<Tuple2<Integer, Point>, Tuple3<Integer, Double, Double>>() {
            @Override
            public Tuple3<Integer, Double, Double> map(Tuple2<Integer, Point> tuple2) {
                return new Tuple3<>(tuple2.f0, tuple2.f1.x, tuple2.f1.y);
            }
        });

        // emit result
        if (params.has("output")) {
            csvPoints.writeAsCsv(params.get("output"), "\n", ",").setParallelism(1);

            // since file sinks are lazy, we trigger the execution explicitly
            env.execute("KMeans Example");
        } else {
            System.out.println("Printing result to stdout. Use --output to specify output path.");
            clusteredPoints.print();
        }
    }

    // *************************************************************************
    //     DATA SOURCE READING (POINTS AND CENTROIDS)
    // *************************************************************************

    private static DataSet<Point> processPoints(DataSource data, ParameterTool params) {
        DataSet<Point> points = data.flatMap(new Pointenizer(params));

        return points;
    };

    private static DataSet<Centroid> processCentroids(DataSource data, ParameterTool params) {
        DataSet<Centroid> centroids = data.flatMap(new Centroidizer(params));

        return centroids;
    };

    public static final class Pointenizer implements FlatMapFunction<Tuple14<String, Integer, Integer, Integer, Integer, Integer, Double, Double, Integer, Integer, Integer, Integer, Integer, Integer>, Point> {
        private final ParameterTool params;

        public Pointenizer(ParameterTool params) {
            this.params = params;
        }

        @Override
        public void flatMap(Tuple14<String, Integer, Integer, Integer, Integer, Integer, Double, Double, Integer, Integer, Integer, Integer, Integer, Integer> tuple, Collector<Point> out) {
            if (tuple.f0.equals("GSM") || tuple.f0.equals("UMTS")) {
                //mnc is net and tuple.f2 in that case
                if (this.params.has("mnc")) {
                    String[] mnc = this.params.get("mnc").split(",");

                    for (int i = 0; i < mnc.length; i++) {
                        if (Integer.parseInt(mnc[i]) == tuple.f2)
                            out.collect(new Point(tuple.f6, tuple.f7));
                    }
                } else
                    out.collect(new Point(tuple.f6, tuple.f7));
            }
        }
    }

    public static final class Centroidizer implements FlatMapFunction<Tuple14<String, Integer, Integer, Integer, Integer, Integer, Double, Double, Integer, Integer, Integer, Integer, Integer, Integer>, Centroid> {
        private final ParameterTool params;

        public Centroidizer(ParameterTool params) {
            this.params = params;
        }

        @Override
        public void flatMap(Tuple14<String, Integer, Integer, Integer, Integer, Integer, Double, Double, Integer, Integer, Integer, Integer, Integer, Integer> tuple, Collector<Centroid> out) {
            if (tuple.f0.equals("LTE")) {
                if (this.params.has("mnc")) {
                    String[] mnc = this.params.get("mnc").split(",");

                    for (int i = 0; i < mnc.length; i++) {
                        if (Integer.parseInt(mnc[i]) == tuple.f2)
                            out.collect(new Centroid(tuple.f4, tuple.f6, tuple.f7));
                    }
                } else
                    out.collect(new Centroid(tuple.f4, tuple.f6, tuple.f7));
            }
        }
    }

    // *************************************************************************
    //     DATA TYPES
    // *************************************************************************

    /**
     * A simple two-dimensional point.
     */
    public static class Point implements Serializable {

        public double x, y;

        public Point() {}

        public Point(double x, double y) {
            this.x = x;
            this.y = y;
        }

        public Point add(Point other) {
            x += other.x;
            y += other.y;
            return this;
        }

        public Point div(long val) {
            x /= val;
            y /= val;
            return this;
        }

        public double euclideanDistance(Point other) {
            return Math.sqrt((x - other.x) * (x - other.x) + (y - other.y) * (y - other.y));
        }

        public void clear() {
            x = y = 0.0;
        }

        @Override
        public String toString() {
            return x + " " + y;
        }
    }

    /**
     * A simple two-dimensional centroid, basically a point with an ID.
     */
    public static class Centroid extends Point {

        public int id;

        public Centroid() {}

        public Centroid(int id, double x, double y) {
            super(x, y);
            this.id = id;
        }

        public Centroid(int id, Point p) {
            super(p.x, p.y);
            this.id = id;
        }

        @Override
        public String toString() {
            return id + " " + super.toString();
        }
    }

    // *************************************************************************
    //     USER FUNCTIONS
    // *************************************************************************

    /** Determines the closest cluster center for a data point. */
    @ForwardedFields("*->1")
    public static final class SelectNearestCenter extends RichMapFunction<Point, Tuple2<Integer, Point>> {
        private Collection<Centroid> centroids;

        /** Reads the centroid values from a broadcast variable into a collection. */
        @Override
        public void open(Configuration parameters) throws Exception {
            this.centroids = getRuntimeContext().getBroadcastVariable("centroids");
        }

        @Override
        public Tuple2<Integer, Point> map(Point p) throws Exception {

            double minDistance = Double.MAX_VALUE;
            int closestCentroidId = -1;

            // check all cluster centers
            for (Centroid centroid : centroids) {
                // compute distance
                double distance = p.euclideanDistance(centroid);

                // update nearest cluster if necessary
                if (distance < minDistance) {
                    minDistance = distance;
                    closestCentroidId = centroid.id;
                }
            }

            // emit a new record with the center id and the data point.
            return new Tuple2<>(closestCentroidId, p);
        }
    }

    /** Appends a count variable to the tuple. */
    @ForwardedFields("f0;f1")
    public static final class CountAppender implements MapFunction<Tuple2<Integer, Point>, Tuple3<Integer, Point, Long>> {

        @Override
        public Tuple3<Integer, Point, Long> map(Tuple2<Integer, Point> t) {
            return new Tuple3<>(t.f0, t.f1, 1L);
        }
    }

    /** Sums and counts point coordinates. */
    @ForwardedFields("0")
    public static final class CentroidAccumulator implements ReduceFunction<Tuple3<Integer, Point, Long>> {

        @Override
        public Tuple3<Integer, Point, Long> reduce(Tuple3<Integer, Point, Long> val1, Tuple3<Integer, Point, Long> val2) {
            return new Tuple3<>(val1.f0, val1.f1.add(val2.f1), val1.f2 + val2.f2);
        }
    }

    /** Computes new centroid from coordinate sum and count of points. */
    @ForwardedFields("0->id")
    public static final class CentroidAverager implements MapFunction<Tuple3<Integer, Point, Long>, Centroid> {

        @Override
        public Centroid map(Tuple3<Integer, Point, Long> value) {
            return new Centroid(value.f0, value.f1.div(value.f2));
        }
    }
}